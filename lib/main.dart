import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/journal_entry.dart';
import 'models/streak_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(StreakHistoryAdapter());
  
  // Open Boxes
  await Hive.openBox('settings');
  await Hive.openBox<JournalEntry>('journals');
  await Hive.openBox<StreakHistory>('streaks');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenith Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0C), // Pure Matte Black
        cardColor: const Color(0xFF13131A), // Deep Charcoal Card
        primaryColor: const Color(0xFF2563EB), // Solid Blue Accent
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          secondary: Color(0xFF059669), // Emerald Green Accent
          surface: Color(0xFF13131A),
          error: Color(0xFFDC2626), // Solid Red Accent
        ),
        fontFamily: 'Arial',
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // Boxes
  late Box _settingsBox;
  late Box<JournalEntry> _journalBox;
  late Box<StreakHistory> _streakBox;

  // Streak State
  late DateTime _streakStartDate;
  late Timer _streakTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _journalBox = Hive.box<JournalEntry>('journals');
    _streakBox = Hive.box<StreakHistory>('streaks');
    
    _loadOrCreateStreak();
    
    // Timer to update elapsed time every second
    _streakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_streakStartDate);
        });
      }
    });
  }

  @override
  void dispose() {
    _streakTimer.cancel();
    super.dispose();
  }

  void _loadOrCreateStreak() {
    final storedDateStr = _settingsBox.get('streak_start_date');
    if (storedDateStr == null) {
      _streakStartDate = DateTime.now();
      _settingsBox.put('streak_start_date', _streakStartDate.toIso8601String());
    } else {
      _streakStartDate = DateTime.parse(storedDateStr);
    }
    _elapsed = DateTime.now().difference(_streakStartDate);
  }

  void _resetStreak() {
    final now = DateTime.now();
    final durationDays = now.difference(_streakStartDate).inDays;

    // Log the current completed streak to history (if it was active for at least 1 day or has some value)
    final historyEntry = StreakHistory(
      startDate: _streakStartDate,
      endDate: now,
      durationDays: durationDays > 0 ? durationDays : 0,
    );
    _streakBox.add(historyEntry);

    // Set new start date
    setState(() {
      _streakStartDate = now;
      _settingsBox.put('streak_start_date', _streakStartDate.toIso8601String());
      _elapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      OverviewTab(
        elapsed: _elapsed,
        onReset: _showResetConfirmation,
        onSurf: _launchBoxBreathing,
      ),
      JournalTab(box: _journalBox),
      AnalyticsTab(box: _streakBox, currentStreakDays: _elapsed.inDays),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0A0A0C),
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF8E8E93),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield),
              label: 'OVERVIEW',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_outlined),
              activeIcon: Icon(Icons.edit_note),
              label: 'JOURNAL',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'ANALYTICS',
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13131A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'RESET CURRENT STREAK',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        content: const Text(
          'Are you sure you want to log this streak and start a new cycle? This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () {
              _resetStreak();
              Navigator.pop(context);
            },
            child: const Text('RESET STREAK', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _launchBoxBreathing() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => const BoxBreathingOverlay(),
    );
  }
}

// ==================== OVERVIEW TAB ====================
class OverviewTab extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onReset;
  final VoidCallback onSurf;

  const OverviewTab({
    super.key,
    required this.elapsed,
    required this.onReset,
    required this.onSurf,
  });

  @override
  Widget build(BuildContext context) {
    final days = elapsed.inDays;
    final hours = elapsed.inHours % 24;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'ZENITH FOCUS SUITE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Color(0xFF8E8E93),
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          
          // Beautiful Flat Streak Indicator
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFF13131A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF059669), // Solid Emerald Green
                  width: 4,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'DAYS ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),

          // Minimal Countdown display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF13131A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF202028), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn(hours, 'HRS'),
                _buildTimeDivider(),
                _buildTimeColumn(minutes, 'MIN'),
                _buildTimeDivider(),
                _buildTimeColumn(seconds, 'SEC'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Actions
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), // Solid Blue Accent
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onSurf,
            child: const Text(
              'SURF THE URGE',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDC2626), width: 1.0), // Crimson Red Outline
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onReset,
            child: const Text(
              'RESET ACTIVE CYCLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(int value, String label) {
    final valStr = value.toString().padLeft(2, '0');
    return Column(
      children: [
        Text(
          valStr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDivider() {
    return const Text(
      ':',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF33333D),
      ),
    );
  }
}

// ==================== JOURNAL TAB ====================
class JournalTab extends StatefulWidget {
  final Box<JournalEntry> box;

  const JournalTab({super.key, required this.box});

  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  final _textController = TextEditingController();

  void _addJournalEntry() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      content: content,
    );

    widget.box.add(entry);
    _textController.clear();
    Navigator.pop(context);
    setState(() {}); // Refresh lists
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.box.values.toList().reversed.toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MINDFULNESS JOURNAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.all(8),
                ),
                icon: const Icon(Icons.add, size: 18),
                onPressed: _showAddJournalDialog,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'No entries recorded. Tap plus to log your reflections.',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF202028), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(entry.timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                  onPressed: () {
                                    entry.delete();
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.content,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddJournalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF13131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NEW JOURNAL ENTRY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 6,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Record your current thoughts, triggers, or commitments...',
                  hintStyle: const TextStyle(color: Color(0xFF4C4C55), fontSize: 13),
                  fillColor: const Color(0xFF0A0A0C),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF202028), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _addJournalEntry,
                child: const Text(
                  'SAVE ENTRY',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ).then((_) {
      // Trigger list refresh on sheet close
      setState(() {});
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// ==================== ANALYTICS TAB ====================
class AnalyticsTab extends StatelessWidget {
  final Box<StreakHistory> box;
  final int currentStreakDays;

  const AnalyticsTab({
    super.key,
    required this.box,
    required this.currentStreakDays,
  });

  @override
  Widget build(BuildContext context) {
    final history = box.values.toList().reversed.toList();
    
    // Calculate statistics
    int bestStreak = currentStreakDays;
    for (var entry in history) {
      if (entry.durationDays > bestStreak) {
        bestStreak = entry.durationDays;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ANALYTICS & STATS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Stat Overview Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF202028), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BEST STREAK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$bestStreak DAYS',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669), // Solid Emerald Green
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131A),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF202028), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL CYCLES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${history.length + 1}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB), // Solid Blue
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'STREAK HISTORY RECORD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'No completed cycles logged in database yet.',
                      style: TextStyle(color: Color(0xFF4C4C55), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13131A),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1A1A22), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatShortDate(item.startDate)} - ${_formatShortDate(item.endDate)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'COMPLETED CYCLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${item.durationDays}D',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ==================== BOX BREATHING OVERLAY ====================
class BoxBreathingOverlay extends StatefulWidget {
  const BoxBreathingOverlay({super.key});

  @override
  State<BoxBreathingOverlay> createState() => _BoxBreathingOverlayState();
}

class _BoxBreathingOverlayState extends State<BoxBreathingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  
  // Timer State
  int _secondsLeft = 16; // 4s per phase * 4 phases
  int _currentCycle = 1;
  String _currentPhaseText = 'INHALE DEEPLY';
  Color _phaseColor = const Color(0xFF2563EB); // Dynamic solid color indicator

  late Timer _cycleTimer;

  @override
  void initState() {
    super.initState();
    
    // Animation controller for smooth circle scale
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _scaleAnimation = Tween<double>(begin: 100.0, end: 220.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startBreathingLoop();
  }

  @override
  void dispose() {
    _cycleTimer.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _startBreathingLoop() {
    _animController.forward(); // Start inhaling
    
    _cycleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _secondsLeft--;

        if (_secondsLeft <= 0) {
          _secondsLeft = 16;
          _currentCycle++;
        }

        // Determine current phase based on seconds elapsed in 16s cycle
        final cycleSecond = 16 - _secondsLeft;
        
        if (cycleSecond < 4) {
          // Inhale: 0s to 4s (Circle scales UP)
          _currentPhaseText = 'INHALE DEEPLY';
          _phaseColor = const Color(0xFF2563EB); // Solid Blue
          if (!_animController.isAnimating && _animController.value < 1.0) {
            _animController.forward();
          }
        } else if (cycleSecond < 8) {
          // Hold: 4s to 8s (Circle stays UP)
          _currentPhaseText = 'HOLD BREATH';
          _phaseColor = const Color(0xFF059669); // Solid Emerald Green
          _animController.stop();
        } else if (cycleSecond < 12) {
          // Exhale: 8s to 12s (Circle scales DOWN)
          _currentPhaseText = 'EXHALE SLOWLY';
          _phaseColor = const Color(0xFFDC2626); // Solid Red Accent
          if (!_animController.isAnimating && _animController.value > 0.0) {
            _animController.reverse();
          }
        } else {
          // Hold: 12s to 16s (Circle stays DOWN)
          _currentPhaseText = 'HOLD BREATH';
          _phaseColor = const Color(0xFF8E8E93); // Solid Grey
          _animController.stop();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C), // Force full matte black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'URGE SURFER ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Spacer(),
              
              // Dynamic Animated Expanding Circle
              Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: _scaleAnimation.value,
                      height: _scaleAnimation.value,
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _phaseColor,
                          width: 4,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),

              // Animated Breathing Commands
              Center(
                child: Text(
                  _currentPhaseText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _phaseColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'CYCLE $_currentCycle • PHASE SECOND: ${(4 - (_secondsLeft % 4)) == 0 ? 4 : (4 - (_secondsLeft % 4))}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13131A),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF202028), width: 1.0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'EXIT SURFER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

# Zenith Mobile

Zenith Mobile is a premium, distraction-free mindfulness and self-control application built for iOS and Android. Replicating the core desktop suite, Zenith Mobile helps you surf urges, calculate streaks, journal your recovery, and shield your device from PMO system-wide.

---

## Technical Architecture

Zenith Mobile utilizes a cross-platform tech stack coupled with native bridges to build system-level controls:

1. **Cross-Platform UI (Flutter / React Native):** Shares 90% of UI code including the main dashboard overview, past streaks history, encrypted local journals, and the guided box-breathing intervention screens.
2. **Android Accessibility Module:** Real-time web URL parsing and passive screen text scanning to match mature keyword patterns and dynamically render overlays (mindful pauses).
3. **Android VPN Service Module:** An offline, loopback DNS filter (`VpnService`) running entirely on-device to block mature connections system-wide.
4. **iOS Screen Time Module:** Integrates with Apple's `FamilyControls` and `ManagedSettings` frameworks to restrict forbidden apps, block adult web categories, and prevent app deletion.
5. **Local Secure Database:** Powered by **Hive** (fast NoSQL) or **SQLite (Drift)** to run completely offline with end-to-end encrypted journals.

---

## Workspace Setup

This repository is designated for the Zenith Mobile client. 

### Prerequisites

* **For Flutter development:**
  * Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
  * Install Android Studio (for Android build tools) and Xcode (for iOS development, macOS required).
* **For React Native development:**
  * Install [Node.js](https://nodejs.org/).
  * Install [React Native CLI](https://reactnative.dev/docs/environment-setup) or Expo.

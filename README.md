<div align="center">
  <img
    src="Overhead/Assets.xcassets/AppIcon.appiconset/1024.png"
    alt="Overhead app icon"
    width="128"
    height="128"
  />

  # Overhead

  **Know what is due, what is paid, and what to set aside next.**

  A private, local-first iOS app for planning recurring expenses across months,
  currencies, and countries, with optional iCloud sync.

  ![Platform](https://img.shields.io/badge/platform-iOS%2026%2B-000000?style=flat-square&logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-5.0-F05138?style=flat-square&logo=swift&logoColor=white)
  [![State CI](https://github.com/victorcastro/overhead-app/actions/workflows/main-pipeline.yml/badge.svg)](https://github.com/victorcastro/overhead-app/actions/workflows/main-pipeline.yml)
</div>

## How it works ?

**Home** shows the selected month split into still to set aside, unpaid, paid, and saving ahead for future annual
costs. Swipe left or right to change month, from the current year minus one to plus one.

**Calendar** shows one card per month, colored against the year's average, with a read-only breakdown on tap. Swipe to
change year, within the range your data actually covers.

**Settings** holds the base currency, decimals, tracked locations, exchange rates, and iCloud controls.

Recurring expenses repeat monthly, annually, at a custom interval, or once. Each can end never, after a number of
payments, or on a date. When a due day does not exist in a target month, Overhead uses that month's final valid day.

## Requirements

- macOS with Xcode 26 or later
- iOS 26.0 or later
- SwiftLint, when running the repository's lint command locally

The project has no third-party runtime dependencies and does not require dependency installation.

## Getting started

1. Clone or fork this repository.
2. Open `Overhead.xcodeproj` in Xcode.
3. Select the `Overhead` scheme and an iOS 26+ simulator or device.
4. Build and run with <kbd>⌘</kbd><kbd>R</kbd>.

## Data and privacy

All expense data is stored locally on the device using SwiftData — the app needs no account and no network connection
to work. iCloud sync is off by default; turning it on in Settings keeps everything inside the user's own private
iCloud account, and turning it back off simply stops syncing without deleting anything. Settings also has a separate,
explicit action to erase the app's iCloud data, so nothing is ever deleted as a side effect of another setting.

Settings also lets you download your data as a file for backup or transfer, and upload one back in, choosing whether
to merge it with what's on the device or replace everything.

There is no analytics, no account system, and no remote backend beyond the user's own iCloud.

> [!IMPORTANT]
> Currency conversion uses static reference rates, not a live financial service, and should not be treated as
> authoritative.

## Contributing

Contributions are welcome. Bug reports, accessibility improvements, tests, documentation, and focused feature proposals
are all valuable.

1. Check existing issues before starting substantial work.
2. Fork the repository and create a focused branch:

   ```sh
   git switch -c feature/short-description
   ```

3. Keep changes small and aligned with the existing SwiftUI and SwiftData architecture.
4. Add or update tests when changing recurrence, totals, paid-state, or currency behavior.
5. Run the build, tests, and SwiftLint before opening a pull request.
6. Explain the user-facing outcome and include screenshots for visual changes.

Please avoid committing personal financial data, signing certificates, provisioning profiles, build output, or Xcode user
state. The repository's `.gitignore` already excludes the most common local files.

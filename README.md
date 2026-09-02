<div align="center">
  <img
    src="SinkingFound/Assets.xcassets/AppIcon.appiconset/1024.png"
    alt="SinkingFound app icon"
    width="128"
    height="128"
  />

  # SinkingFound

  **Know what is due, what is paid, and what to set aside next.**

  A private, local-first iOS app for planning recurring expenses across months,
  currencies, and countries.

  ![Platform](https://img.shields.io/badge/platform-iOS%2018%2B-000000?style=flat-square&logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-5.0-F05138?style=flat-square&logo=swift&logoColor=white)
  ![License](https://img.shields.io/badge/license-MIT-34C759?style=flat-square)
  [![State CI](https://github.com/victorcastro/sinking-found/actions/workflows/main-pipeline.yml/badge.svg)](https://github.com/victorcastro/sinking-found/actions/workflows/main-pipeline.yml)
</div>

---

## About

SinkingFound turns fixed and recurring costs into a clear monthly plan. It helps answer three practical questions:

1. How much is due this month?
2. How much has already been paid?
3. How much should be saved now for annual expenses?

Everything is stored locally on the device with SwiftData. The app does not require an account, a backend, or a network
connection.

## Highlights

- **Monthly expense dashboard** — see paid, unpaid, and saving-ahead amounts at a glance.
- **Annual calendar** — compare all twelve months and jump directly to any month.
- **Current-month marker** — quickly find the present month in the annual view.
- **Flexible schedules** — monthly, annual, one-time, or custom intervals from 2 to 36 months.
- **Annual sinking funds** — spread upcoming yearly expenses into manageable monthly shares.
- **Multi-currency support** — record expenses in EUR, PEN, or USD and view normalized EUR totals.
- **Location filters** — separate or combine expenses from Spain and Peru.
- **Payment history** — track paid status independently for every monthly period.
- **Native experience** — built entirely with SwiftUI and system controls, including VoiceOver labels.
- **Local-first privacy** — financial data stays in the app's on-device SwiftData store.

## How it works

### Monthly dashboard

The dashboard calculates a plan for the selected month and groups expenses into:

| Section | Purpose |
| --- | --- |
| Still to set aside | Unpaid expenses plus the monthly share of future annual costs |
| Unpaid | Expenses due during the selected month that are not marked as paid |
| Paid | Completed expenses for that monthly period |
| Saving ahead | Monthly contributions toward annual expenses due later |

### Annual calendar

Use the calendar button in the dashboard toolbar to open the yearly overview. Each card displays one month's fixed-cost
total, with a relative bar and color indicating whether that month is normal, above average, or especially heavy. Select
a card to return to the dashboard and inspect that month's expenses.

### Recurrence rules

- **Monthly:** repeats every month from its initial due date.
- **Annual:** repeats in the same month and day every year.
- **One-time:** appears only in its original month.
- **Other:** repeats at a configurable interval measured in months.

When a due day does not exist in a target month, SinkingFound uses that month's final valid day.

## Requirements

- macOS with Xcode 16 or later
- iOS 18.0 or later
- SwiftLint, when running the repository's lint command locally

The project has no third-party runtime dependencies and does not require dependency installation.

## Getting started

1. Clone or fork this repository.
2. Open `SinkingFound.xcodeproj` in Xcode.
3. Select the `SinkingFound` scheme and an iOS 18+ simulator or device.
4. Build and run with <kbd>⌘</kbd><kbd>R</kbd>.

You can also build from the command line:

```sh
xcodebuild \
  -project SinkingFound.xcodeproj \
  -scheme SinkingFound \
  -sdk iphonesimulator \
  -configuration Debug \
  build CODE_SIGNING_ALLOWED=NO
```

Run the test suite with a simulator available on your machine:

```sh
xcodebuild test \
  -project SinkingFound.xcodeproj \
  -scheme SinkingFound \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Run lint checks separately with:

```sh
swiftlint lint
```

## Continuous integration

The [continuous integration workflow](.github/workflows/main-pipeline.yml) validates relevant pushes to `main`
and pull requests. A lightweight
Linux job first checks that every Xcode target uses the same semantic `MARKETING_VERSION` and that `CHANGELOG.md` contains
a dated section for it. The macOS build only starts after this inexpensive check passes.

The macOS job performs SwiftLint validation, builds the app, and runs the unit tests in a single invocation to avoid
duplicating setup and compilation time.

The workflow cancels superseded runs from the same pull request, ignores documentation-only changes, skips UI performance
tests, and uploads an `.xcresult` bundle only after a failure. Failure diagnostics expire after seven days to minimize
artifact storage.

After a successful push or merge to `main`, the pipeline creates an annotated `v<MARKETING_VERSION>` Git tag for the
validated commit. Existing tags are never overwritten; increment the Xcode marketing version and add its dated changelog
section before creating the next release tag. Pull requests only run validations and never create tags.

## Project structure

```text
SinkingFound/
├── Design/
│   └── Theme.swift                  # Shared colors, spacing, and card styling
├── Features/
│   ├── Calendar/
│   │   └── CalendarView.swift       # Twelve-month expense overview
│   ├── Dashboard/
│   │   ├── DashboardComponents.swift
│   │   └── DashboardView.swift      # Home screen for the current month
│   ├── ExpenseForm/
│   │   └── ExpenseFormView.swift    # Create, edit, and delete expenses
│   ├── Root/
│   │   └── RootTabView.swift        # Home, Calendar, and Settings tabs
│   └── Settings/
│       ├── LocationSettingsView.swift
│       └── SettingsView.swift       # iCloud, base currency, locations, exchange rates
├── Models/
│   ├── AppSettings.swift            # Base currency, locations, and the iCloud sync flag
│   ├── CloudDataEraser.swift        # Deletes this app's data from the private iCloud database
│   ├── Currency.swift               # Currency metadata and money formatting
│   ├── ExpenseAttributes.swift      # Frequency, category, and location types
│   ├── ExpenseStore.swift           # Builds the model container, with or without CloudKit
│   ├── FixedExpense.swift           # SwiftData persistence model
│   ├── KeyValueStore.swift          # Testable seam over NSUbiquitousKeyValueStore
│   ├── Location.swift               # Country catalog
│   └── MonthPlan.swift              # Monthly planning calculations
├── SinkingFound.entitlements        # iCloud container, CloudKit, and key-value store
└── SinkingFoundApp.swift            # App entry point and model container
```

The codebase keeps persistence and recurrence rules in the model layer, month calculations in `MonthPlan`, and native
SwiftUI views inside feature folders. This separation makes the financial rules testable without depending on UI code.

## Data and privacy

- Expense data is persisted locally using SwiftData.
- iCloud sync is off by default and only runs when it is turned on in Settings. When enabled, the expenses go to the
  user's private CloudKit database and the base currency and locations go to `NSUbiquitousKeyValueStore`; nothing leaves
  the user's own iCloud account. Turning it off stops syncing without deleting anything on either side.
- Settings has a separate, explicit action to delete this app's data from iCloud. It never runs as a side effect of
  turning sync off.
- There is currently no analytics, account system, or remote backend beyond the user's own iCloud.
- Deleting the app may also remove its local data unless it is restored through an operating-system backup.

Enabling iCloud sync requires the *iCloud → CloudKit* and *Background Modes → Remote notifications* capabilities on the
`SinkingFound` target, with the container `iCloud.dev.victorcastro.SinkingFound`. The schema is created in CloudKit's
Development environment on first run and must be deployed to Production before an App Store release.

> [!IMPORTANT]
> Currency conversion currently uses static reference rates defined in `Currency.swift`. These values are not fetched
> from a live financial service and should not be treated as authoritative exchange rates.

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

## Roadmap

- [ ] Configurable and live exchange rates
- [ ] Additional currencies and locations
- [ ] Search, category filters, and richer expense insights
- [ ] Import and export for backups and portability
- [ ] Optional iCloud synchronization
- [ ] Localization beyond English
- [ ] Expanded unit and UI test coverage

Roadmap items describe possible directions, not guaranteed release commitments. If you would like to work on one, open an
issue first so the scope can be discussed.

## Changelog

Release history and notable changes are documented in [CHANGELOG.md](CHANGELOG.md).

## License

SinkingFound is available under the [MIT License](LICENSE).

Copyright © 2026 Victor Castro.

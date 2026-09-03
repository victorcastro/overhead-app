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
  currencies, and countries, with optional iCloud sync.

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

Everything is stored locally on the device with SwiftData. The app needs no account, no backend, and no network
connection. Syncing across devices is available through the user's own iCloud, and it is off until they turn it on.

## Highlights

- **Three tabs** — Home for the current month, Calendar for the year, Settings for everything else.
- **Monthly expense dashboard** — see paid, unpaid, and saving-ahead amounts at a glance.
- **Annual calendar** — compare all twelve months of a year, with each month colored against that year's average.
- **Current-month marker** — quickly find the present month in the annual view.
- **Flexible schedules** — monthly, annual, one-time, or custom intervals from 2 to 36 months.
- **Annual sinking funds** — spread upcoming yearly expenses into manageable monthly shares.
- **Multi-currency support** — record expenses in EUR, GBP, PEN, or USD and read every total in your base currency.
- **Location filters** — pick the countries you track from a full catalog and filter the dashboard by them.
- **Payment history** — track paid status independently for every monthly period.
- **Native experience** — built entirely with SwiftUI and system controls, including VoiceOver labels.
- **Local-first privacy** — data stays on device unless you opt into iCloud sync, which you can undo and erase.

## How it works

### Monthly dashboard

The Home tab calculates a plan for the selected month and groups expenses into:

| Section | Purpose |
| --- | --- |
| Still to set aside | Unpaid expenses plus the monthly share of future annual costs |
| Unpaid | Expenses due during the selected month that are not marked as paid |
| Paid | Completed expenses for that monthly period |
| Saving ahead | Monthly contributions toward annual expenses due later |

A recurring expense can end: never, after a number of payments counting the first one, or on a date it may not fall
past. One-time expenses have no end rule. A series that has ended disappears from later months, from the annual totals
and from the share saved ahead, and its final payment reads "last payment" in the list.

It opens on the current month. Swiping left or right moves one month at a time, and the calendar button in the
navigation bar opens a picker with the twelve months of a year. Both cover the same window, from the current year minus
one to the current year plus one, and the picker adds a shortcut back to this month.
Marking an expense as paid records the month you are looking at, and adding a new expense always anchors it to the real
current month.

### Annual calendar

The Calendar tab shows one card per month of a year, named in the navigation bar. It opens on the current year. Each
card shows that month's fixed-cost total, a bar scaled against the year's heaviest month, and a color comparing
it to the year's monthly average: normal up to 110%, above average up to 150%, heavy beyond that. It reads every
expense, so the dashboard's location filter does not narrow these totals.

Swiping left or right moves one year at a time. The range comes from the data: back to the oldest year holding a
payment and forward to the last one, capped five years ahead so an expense without an end date does not open an endless
range. Years with nothing in them sit inside that range and can still be swiped through, and a "This year" button sits
next to the title while the year on screen is not the current one.

Tapping a card opens a read-only summary of that month: its total plus the expenses split into unpaid, paid and saving
ahead. Marking as paid and editing stay on Home.

### Settings

The Settings tab holds the base currency, the tracked locations, the reference exchange rates, and the iCloud controls.
Deleting a location moves the expenses that used it back to Undefined; with no locations defined, the dashboard filter
and the expense form's location picker stay hidden.

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

## Project structure

```text
SinkingFound/
├── Design/
│   └── Theme.swift                  # Shared colors, spacing, and card styling
├── Features/
│   ├── Calendar/
│   │   ├── CalendarView.swift       # Twelve-month expense overview, one page per year
│   │   └── MonthDetailSheet.swift   # Read-only breakdown of a single month
│   ├── Dashboard/
│   │   ├── DashboardComponents.swift
│   │   ├── DashboardView.swift      # Home screen for the selected month
│   │   └── MonthPickerSheet.swift   # Month picker opened from the Home toolbar
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
│   ├── MonthPlan.swift              # Monthly planning calculations
│   ├── MonthWindow.swift            # The range of months Home can reach
│   └── YearWindow.swift             # The range of years the calendar can reach
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
- [ ] Additional currencies
- [ ] Browsing months other than the current one
- [ ] Search, category filters, and richer expense insights
- [ ] Import and export for backups and portability
- [ ] Localization beyond English
- [ ] Expanded unit and UI test coverage

Roadmap items describe possible directions, not guaranteed release commitments. If you would like to work on one, open an
issue first so the scope can be discussed.

## Changelog

Release history and notable changes are documented in [CHANGELOG.md](CHANGELOG.md).

## License

SinkingFound is available under the [MIT License](LICENSE).

Copyright © 2026 Victor Castro.

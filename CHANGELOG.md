# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-03

### Added

- Tab bar with three top-level screens: Home (the current month), Calendar (the twelve monthly totals of a year), and
  Settings. Each tab keeps its own navigation stack and its state across switches.
- Optional iCloud sync, off by default, toggled in Settings and disabled without an iCloud session. Expenses sync
  through CloudKit and the base currency and locations through the ubiquitous key-value store, with no app restart.
- Settings action to delete this app's data from the private iCloud database, behind a confirmation dialog. It turns
  sync off first, keeps the data on the device, and reports failures in an alert.
- Base currency picker in Settings (USD default, plus EUR, PEN, GBP). Every total is shown in it and each expense is
  converted from the currency it was entered in; the choice is persisted locally.
- User-managed locations in Settings: search a country catalog and pick which countries to track. Deleting one moves its
  expenses back to Undefined, and with none defined the location filter and picker stay hidden.
- GitHub Actions pipeline that validates the project version against a dated changelog section, lints, builds for the
  simulator, runs the unit tests, and tags the release on `main`.

### Changed

- The annual calendar and Settings are tabs instead of modal sheets, so their toolbar buttons are gone and the dashboard
  toolbar keeps only the add-expense button.
- The annual calendar reads every expense directly instead of receiving the dashboard's, so the location filter no
  longer narrows the yearly totals.
- Opening the SwiftData store no longer deletes it when CloudKit is unavailable; it falls back to local storage, and the
  wipe-and-retry path is now reserved for an unreadable local store.

### Removed

- Month selection. The dashboard is pinned to the current month, and tapping a month in the annual calendar only
  highlights it.

## [1.0.0] - 2026-09-02

### Added

- Monthly dashboard with paid, unpaid, and annual saving-ahead summaries.
- Fixed-expense creation and editing with frequency, category, location, currency, and due-date support.
- Payment tracking for each monthly expense period.
- Location filters for viewing expenses across supported places.
- Annual calendar with all twelve monthly expense totals and year navigation.
- Visual comparison of normal, above-average, and high-expense months.
- Current-month indicator and direct month selection from the annual calendar.
- Dark appearance, native SwiftUI controls, and VoiceOver labels for key actions.

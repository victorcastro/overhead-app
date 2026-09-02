# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-03

### Added

- Tab bar navigation with three top-level screens: Home (the current month), Calendar (the annual totals), and Settings.
- Optional iCloud sync, off by default and toggled from Settings. It covers the expenses, the base currency, and the
  locations, and applies without restarting the app. Turning it off keeps both the data on the device and the copy in
  iCloud, so turning it back on merges them again.
- Settings action to delete this app's data from the user's private iCloud database. It turns syncing off first, leaves
  the data on the device untouched, and asks for confirmation because it cannot be undone.
- Settings screen to choose the base currency (USD default, plus EUR, PEN, GBP); every total is shown in that currency and
  each expense is converted from the currency it was entered in. The choice is persisted locally.
- User-managed locations in Settings: search a country catalog and pick which countries to track. Expenses default to
  Undefined. With no locations defined, the dashboard location filter and the expense form's location picker stay hidden.
  Deleting a location moves the expenses that used it back to Undefined. Choices are persisted locally.
- Resource-conscious GitHub Actions workflow for version checks, changelog validation, linting, simulator builds, and
  unit tests, followed by automatic version tagging on `main`.

### Changed

- The annual calendar and the settings screen are now tabs instead of modal sheets, so they no longer open from the
  dashboard toolbar. The dashboard toolbar keeps only the add-expense button.
- The annual calendar shows every expense regardless of the dashboard's location filter.

### Removed

- Month selection. The dashboard always shows the current month, and tapping a month in the annual calendar no longer
  changes it.

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

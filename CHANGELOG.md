# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-09-03

### Added

- Month picker on Home, opened with the calendar button in the navigation bar. It shows the twelve months of a year in
  a grid, marks the current and the selected one, and moves between years within a window of the current year plus or
  minus one. A "This month" shortcut jumps back to today.
- Swipe between months on Home. Dragging from the left edge toward the centre goes back a month and dragging from the
  right edge goes forward, across the same window the picker offers. It stops at the ends instead of wrapping around.
- Home now reflects the selected month everywhere: the title, the summary card, the unpaid, paid and saving-ahead
  sections, the empty state, and the paid toggle, which records the period you are looking at. Editing an expense opens
  the form on that same month, while the add button still anchors a new expense to the real current month.
- Swipe between years in the Calendar tab, over a range the data decides: back to the oldest year that holds a payment
  and forward to the last one, capped at five years ahead so an expense that never ends does not open an endless range.
  Years with nothing in them stay in the middle of the range and can be swiped through. The navigation bar carries the
  year on screen instead of a fixed screen name, and a "This year" button appears there whenever it is not the current
  one.
- Month detail in the Calendar tab. Tapping a month card opens a read-only sheet with that month's fixed-cost total and
  its expenses split into unpaid, paid and saving ahead. Nothing can be changed from there.
- An end rule for recurring expenses, set in the form: never, after a number of payments, or on a date. The count
  includes the first payment, and the date is the last day an expense may fall on. One-time expenses do not offer it.
  Once a series ends it stops appearing in the month, in the annual totals and in the share of annual expenses saved
  ahead, and its final payment is labelled "last payment" in the list.
- Decimal places setting, under a new Amounts section in Settings. It applies to every amount shown across Home,
  Calendar, and the expense form, accepts 0 to 4 decimals, defaults to 2, and syncs through iCloud with the other
  settings.

### Changed

- Minimum deployment target raised to iOS 26.0 for every target, including the project-level build configurations.
  Xcode 26 is now required to build, and CI runs on the `macos-26` runner against an iPhone 17 simulator.
- Test targets now match the app target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.

### Removed

- Year navigation in the Calendar tab. The chevrons beside the year are gone and the year is a fixed label, so the tab
  always shows the twelve months of the current year.

### Fixed

- Amounts on Home no longer drop their decimals. `Money.string` had defaulted to zero decimals, so every caller that
  omitted the argument rounded to whole units. The argument is now required.
- Editing an expense no longer truncates its amount to two decimals. The form filled its amount field with a rounded
  string, so saving after any edit wrote that rounded value back over the stored one.
- The keyboard now closes when the expense form is scrolled, and the return key on the name field moves focus to the
  amount instead of doing nothing.

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
- Two GitHub Actions workflows: pull requests validate the project version against a dated changelog section and then
  lint, build, and test; merges to `main` do the same and tag the release afterwards.

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

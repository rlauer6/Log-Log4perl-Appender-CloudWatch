# Release Notes — Amazon::CloudWatchLogs v1.0.4

**Released:** Thu Jul 2, 2026
**Author:** Rob Lauer <rclauer@gmail.com>

---

## Overview

This is a patch release with a small but user-facing improvement to
the `parse_start_time` function, making relative time expressions
involving minutes more natural and intuitive.

---

## What's Changed

### Bug Fixes / Improvements

#### `parse_start_time` — More Natural Minute Shorthand (`Amazon::CloudWatchLogs`)

Previously, specifying a relative start time using the short minute
notation (e.g. `1m` or `1 m`) was handled inconsistently when passed
through to `Date::Manip`. This release normalises those forms to the
`min` keyword that `Date::Manip` expects, before attempting any
natural-language date parsing.

- Input forms like `1m` and `1 m` are now correctly converted to `1
  min` prior to `Date::Manip` parsing.
- Short-circuit logic has been added so that the compact formats
  (`Nd`, `Nh`, `Nm`) bypass `Date::Manip` entirely, improving
  performance and avoiding ambiguity.

**Examples that now work as expected:**

```
aws-logs -t 30m  ...   # 30 minutes ago (compact — bypasses Date::Manip)
aws-logs -t '1m' ...   # 1 minute ago  (normalised before Date::Manip parsing)
```

---

## Files Changed

| File | Change |
|------|--------|
| `lib/Amazon/CloudWatchLogs.pm.in` | Fixed `parse_start_time` — normalise `m`/`min` shorthand; short-circuit compact formats |
| `VERSION` | Bumped to `1.0.4` |
| `ChangeLog` | Updated |
| `release-notes.md` | Updated |
| `release-notes/release-notes-1.0.3.md` | Added |

---

## Upgrading

No breaking changes. This release is a drop-in replacement for v1.0.3.

```bash
cpanm Amazon::CloudWatchLogs
```

---

## Previous Release

See [release notes for v1.0.3](/release-notes/release-notes-1.0.3.md)
for details of stream draining improvements and descending stream
fetch order introduced in the prior release.

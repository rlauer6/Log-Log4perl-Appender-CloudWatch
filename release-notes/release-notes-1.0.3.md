# Amazon::CloudWatchLogs 1.0.3 Release Notes

**Released:** 2026-06-30
**Distribution:** Amazon-CloudWatchLogs
**CPAN Author:** Rob Lauer `<rclauer@gmail.com>`

---

## Overview

Version 1.0.3 delivers targeted improvements to log stream discovery and event retrieval. Stream pagination is now significantly more efficient when a `--start-time` window is in use, and multi-stream event output is now correctly ordered by timestamp across all streams in a single polling pass. A stream-drain detection mechanism has also been added to `get-stream` to avoid unnecessary API calls once a stream has been fully consumed.

---

## What's Changed

### `fetch_streams` — Smarter, More Efficient Stream Discovery

#### Streams fetched newest-first

The `DescribeLogStreams` API call now passes `descending => 1`, returning streams ordered from most-recently-active to oldest. Previously streams were returned in ascending order (oldest to newest), which required paginating through all older streams before reaching the relevant ones.

#### Early pagination exit when outside the requested time window

When `--start-time` is specified, pagination now stops immediately upon encountering a page that contains no streams within the requested window. Because results are now in descending order, an out-of-window page guarantees all subsequent pages are also out-of-window.

#### Removed incorrect fallback behaviour

Previously, if a page of results contained no streams matching the `start_time` filter, the code fell back silently to including *all* streams on that page — including older, irrelevant ones. This fallback has been removed.

**Before (1.0.2):**
```perl
# if no log streams >= start_time, use the whole list
if ( !@relevant ) {
    @relevant = @log_streams;
}
```

**After (1.0.3):**
```perl
# in descending order, once a page yields nothing relevant we've
# paged past the requested window - stop
last LOOP if $start_time && @log_streams && !@relevant;
```

---

### `cmd_get_stream` — Correctness and Efficiency Improvements

#### Cross-stream events now sorted by timestamp

Events from all streams are now accumulated across an entire polling pass and printed together, sorted by timestamp (oldest first). Previously, events were printed immediately per-stream as they were received, which could produce out-of-order output when multiple streams were active simultaneously.

#### Stream-drain detection in non-follow mode

A `%prev_tokens` hash now tracks the previous pagination token for each stream. When the `nextForwardToken` returned by `GetLogEvents` stabilises (i.e. the new token equals the previous token) and no events are returned, the stream is considered fully drained and is removed from the active polling set. This prevents redundant API calls against exhausted streams when running without `--follow`.

---

## Upgrade Notes

This release contains **no breaking changes** and no interface modifications. All existing command-line options and behaviours are preserved.

Users relying on `--start-time` filtering will notice:

- **Faster stream discovery**, particularly when the requested time window excludes a large number of older streams, as unnecessary pagination is avoided.
- **Consistent exclusion** of streams outside the requested time window — the previous fallback behaviour that could cause older, irrelevant streams to appear in results has been removed.
- **Correctly ordered output** when tailing or reading from multiple streams simultaneously.
- **Reduced API calls** in non-follow mode once all streams have been fully consumed.

---

## Files Changed

| File | Change |
|------|--------|
| `VERSION` | Bumped to `1.0.3` |
| `lib/Amazon/CloudWatchLogs.pm.in` | Updated `fetch_streams` and `cmd_get_stream` logic |
| `ChangeLog` | Updated |
| `release-notes.md` | Symlink updated to point to 1.0.3 notes |
| `release-notes/release-notes-1.0.3.md` | New |

---

## Full Changelog

See [ChangeLog](ChangeLog) for the complete history of changes across all releases.
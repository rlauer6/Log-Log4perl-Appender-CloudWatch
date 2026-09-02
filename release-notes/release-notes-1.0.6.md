# Amazon::CloudWatchLogs 1.0.6 Release Notes

**Released:** 2026-09-02
**Distribution:** Amazon-CloudWatchLogs
**Author:** Rob Lauer <rclauer@gmail.com>

---

## Overview

This release introduces smarter stream lifecycle management in follow
mode, adding **idle** and **retired** stream states to reduce
unnecessary `GetLogEvents` API calls against streams that have already
been consumed — particularly for Lambda log groups where stale streams
accumulate quickly.

---

## What's New

### Stream Lifecycle Management in Follow Mode (`cmd_get_stream`)

Streams tracked during `--follow` mode are now maintained in three distinct states:

#### Active
Streams are polled on every pass using the forward pagination token
from the previous `GetLogEvents` call.

#### Idle
When a stream's forward token stabilizes and no new events are
returned, the stream is moved to an **idle** set. Idle streams are
polled once per `--discovery-interval` pass rather than on every poll
cycle. If new events appear, the stream automatically returns to
active.

#### Retired _(Lambda log groups only)_
Idle Lambda streams that remain inactive for more than **20 minutes**
(`LAMBDA_IDLE_LIMIT`) are **retired** from direct polling. Retired
streams are not actively polled but can be reactivated by stream
discovery if `DescribeLogStreams` reports newer activity on the
stream.

This reduces redundant `GetLogEvents` calls against exhausted Lambda
invocation streams while keeping active streams fully responsive.

### Retry Logic for Transient API Errors (`cmd_get_stream`)

`GetLogEvents` calls are now wrapped in an `eval` retry
loop. Transient `API ERROR(599)` failures are retried up to 3 times
with a configurable sleep between attempts, improving resilience
against intermittent connectivity issues.

### Tuned Default Constants

| Constant | Old Value | New Value |
|---|---|---|
| `DISCOVERY_INTERVAL` | `10` seconds | `1` second |
| `ITER_LIMIT` | `50` | `5` |

The discovery interval default is now **1 second**, making stream
discovery significantly more responsive. `ITER_LIMIT` is tightened to
reduce the number of pages fetched per `DescribeLogStreams` call.

### New Constant: `LAMBDA_IDLE_LIMIT`

```
LAMBDA_IDLE_LIMIT = 20 minutes
```

Controls how long a Lambda log stream may remain idle before it is
retired from active polling.

---

## Improvements

### `refresh_streams` Signature Extended

`refresh_streams` now accepts and manages the full stream lifecycle state:

```perl
$self->refresh_streams( \%stream_tokens, \%idle_streams, \%idle_since, \%retired_streams );
```

Previously it only managed `%stream_tokens`. The updated method:

- Promotes idle streams back to active at each discovery interval
  (unless they qualify for retirement).
- Retires Lambda idle streams that have exceeded the idle limit.
- Reactivates retired streams when `DescribeLogStreams` reports newer event activity.

### Improved Idle Detection Logic

The previous approach tracked `%prev_tokens` to detect stream drain in
non-follow mode only. The new implementation:

- Detects idle streams in both follow and non-follow modes using token
  stabilization.
- In non-follow mode, drained streams are removed immediately
  (unchanged behaviour).
- In follow mode, drained streams move to the idle set with their last
  known token recorded.

---

## Documentation Updates

The **Follow Mode** section of the POD documentation has been
substantially expanded to describe:

- The three stream states: active, idle, and retired.
- How each state transitions.
- The rationale for idle/retired behaviour in Lambda log groups.
- An updated description of `--discovery-interval` reflecting its dual
  role in stream discovery and idle-stream polling.

### Updated Option Description

> `--discovery-interval` — Number of seconds between stream discovery
> and idle-stream polling passes when `--follow` is enabled. Default:
> `1`.

---

## Build / Packaging

- `Makefile` updated by `CPAN::Maker::Bootstrapper`:
  - `PACKAGE_VERSION` exported to environment alongside `MODULE_NAME`.
  - `extra-files` target now created explicitly before
    `extra-files.mk` to avoid ordering issues.
  - Variable file generation order corrected in `$(MODULE_PATH).in` recipe.
- `project.mk` added.
- `VERSION` bumped to `1.0.6`.

---

## Upgrade Notes

This release is fully backwards-compatible. No changes are required to existing invocations or configuration. Users following Lambda log groups with `--follow` will notice reduced API call volume for long-running tail sessions.

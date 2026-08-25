# Release Notes — v1.0.5

**Distribution:** `Log-Log4perl-Appender-CloudWatch`
**Date:** 2026-08-25
**Author:** Rob Lauer `<rclauer@gmail.com>`

---

## Overview

Version 1.0.5 is a significant feature and correctness release
covering the `aws-logs` CLI tool (`Amazon::CloudWatchLogs`) and the
`Log::Log4perl::Appender::CloudWatch` appender. It also upgrades the
build infrastructure to the latest `CPAN::Maker::Bootstrapper` managed
files.

---

## What's New

### `Amazon::CloudWatchLogs` (`aws-logs`)

#### New Features

- **`$GIT_SHA` / `$GIT_DIRTY` package variables** — the built module
  now embeds the Git commit SHA and dirty-state descriptor at build
  time.
- **`--discovery-interval`** — replaces `--idle-threshold`. New
  streams are now discovered on a wall-clock timer (default: every 10
  seconds) independent of whether events are arriving, rather than
  after a fixed number of idle polling cycles.
- **`--endpoint-url` shorthand `-u`** — the endpoint URL option now
  accepts `-u` as a short alias.
- **`refresh_streams()`** — new internal method extracted from
  `cmd_get_stream` to handle periodic stream discovery during follow
  mode.
- **`version` command** — display program version and copyright
  (`aws-logs version` or `--version` / `-v`).
- **POD: `version` command documented**, including new
  `--discovery-interval`, updated `--stream`, `--limit`, `--profile`,
  `--region`, and `--start-time` descriptions.

#### Changed Behaviour

- **Follow mode stream discovery** is now time-driven
  (`--discovery-interval`, default 10 s) rather than idle-count-driven
  (`--idle-threshold` is removed).
- **`--limit`** now means the maximum number of _matching_ streams to
  retrieve. It cannot be combined with `--follow` (validated in
  `init()`).
- **`cmd_get_stream`**: paginator setting is now saved and restored
  around the fetch loop.
- **`fetch_streams`**: both `decode_always` and `use_paginator` are
  now saved and restored; `lastEventTimestamp` (not
  `lastIngestionTime`) is used for the time filter; streams without
  `lastEventTimestamp` are now included in results when no
  `--start-time` is set; page size (`page_limit`) is capped to
  `min(limit, ITER_LIMIT)`; early-termination logic refined.
- **`cmd_list_streams`**: `Text::ASCIITable` is now `require`d lazily;
  `allowANSI` is driven by the `--color` flag; the `storedBytes` /
  Size column is removed (always 0 from the API).
- **`init()`**: `discovery_interval`, `sleep_time`, and `limit` are
  now validated (must be > 0; `--limit` with `--follow` is an error).
- **`parse_start_time`**: `Date::Manip` is now `recommends` (not
  `requires`); the `## scandeps: recommends` hint is present.
- **`fmt_message()`** removed (was unused).
- **Removed CLI options:** `--append`, `--format-messages`,
  `--idle-threshold`.
- **`cmd_delete_group`**: unused `$rsp` variable removed.
- **`cmd_create_stream`**: unnecessary `$cwl` assignment removed.
- **`cmd_last_stream`**: unnecessary `$cwl` assignment removed.
- **`_create_stream`**: dead code path (deriving stream prefix from
  group name when stream is empty) removed.
- **Unused constants removed:** `$EVENT_BUFFER_SIZE`,
  `$IDLE_THRESHOLD`, `$MAX_ENTRIES`, `$MAX_RETRIES`,
  `$MESSAGE_FORMAT`, `$RANDOM_SEED`.
- **`Time::HiRes`** import changed from named import to bare `use
  Time::HiRes` with fully-qualified calls.

#### Documentation

- POD updated throughout: commands, options, Follow Mode, Start Time
  Formats, JSON Backend, Shape Deserialization, and Dependencies
  sections revised for accuracy.
- `=encoding utf8` added.
- `=head1 VERSION` section added.

---

### `Log::Log4perl::Appender::CloudWatch`

#### New Features

- **Automatic batch partitioning in `flush_buffer()`** — the buffer is
  now split into legal `PutLogEvents` batches respecting all three AWS
  limits:
  - maximum 10,000 events per batch (`MAX_BATCH_EVENTS`)
  - maximum 1,048,576 bytes per batch (`MAX_BATCH_BYTES`)
  - maximum 24-hour timestamp span per batch (`MAX_BATCH_SPAN_MILLISECONDS`)
  - Each event message is measured with `Encode::encode_utf8` plus the
    26-byte CloudWatch per-event overhead
    (`LOG_EVENT_OVERHEAD_BYTES`).
- **Events are not discarded on flush failure** — if `PutLogEvents`
  fails after all retries, the unsent events remain in the buffer for
  a subsequent flush attempt. Previously the buffer was cleared
  unconditionally.
- **Oversized single events are dropped with a warning** rather than
  blocking the entire buffer.
- **`rejectedLogEventsInfo` handling** — the response from
  `PutLogEvents` is inspected and warnings are emitted for
  `tooOldLogEventEndIndex`, `expiredLogEventEndIndex`, and
  `tooNewLogEventStartIndex`.
- **`event_size()` utility function** added.
- **Constructor validation** — `new()` now croaks if `buffer_size`,
  `max_retries`, or `retry_delay` is ≤ 0.
- **`group_exists()`** now delegates to `describe_group()` instead of
  calling `DescribeLogGroups` directly.
- **`stream_exists()`** now delegates to `describe_stream()` instead
  of calling `DescribeLogStreams` directly.
- **`Encode`** (`encode_utf8`) added as a dependency.
- New constants: `MAX_BATCH_BYTES`, `MAX_BATCH_EVENTS`,
  `LOG_EVENT_OVERHEAD_BYTES`, `MAX_BATCH_SPAN_MILLISECONDS`.

#### Documentation

- Dependencies section updated to list `Amazon::API::CloudWatchLogs`,
  `Class::Accessor::Fast`, `Data::UUID`, `Log::Log4perl::Appender`.
- `buffer_size` note added: `flush_buffer()` now automatically
  partitions larger buffers into legal batches.
- SEE ALSO section updated with links to `Amazon::API`,
  `Amazon::Credentials`, `Amazon::API::Help`.

---

## Dependency Changes

### `cpanfile`

| Change | Module | Version |
|--------|--------|---------|
| Added (`recommends`) | `Date::Manip` | 6.98 |

`Date::Manip` is now a soft recommendation. The `parse_start_time`
function will use it when available for natural-language date parsing;
if absent, only compact formats (`Nd`, `Nh`, `Nm`) are supported.

---

## Build Infrastructure

The following managed files have been updated by `CPAN::Maker::Bootstrapper`:

| File | Change |
|------|--------|
| `.includes/bash-completion.mk` | Added |
| `.includes/local.mk` | Added |
| `.includes/modulino.mk` | Added |
| `.includes/git.mk` | Updated |
| `.includes/help.mk` | Updated — `help` output now paginates via `$PAGER` |
| `.includes/perl.mk` | Updated — see below |
| `.includes/release-notes.mk` | Updated — delegates to `cmb release-notes` |
| `.includes/update.mk` | Updated — drift detection, `.gitignore` merge |
| `.includes/version.mk` | Updated — `release`/`minor`/`major` now depend on `clean` |
| `Makefile` | Updated — see below |
| `.gitignore` | Updated — adds `*.checked`, `*.raw`, `buildspec.yml.current`, `extra-files.mk`, `local/**` |

### Notable build system changes

- **`cmb`** replaces `bootstrapper` as the command name for
  `CPAN::Maker::Bootstrapper`.
- **Template variable expansion** (`resolve-vars`) replaces inline
  `sed` substitution. New template variables: `GIT_SHA`, `GIT_DIRTY`,
  `GIT_USER`, `GIT_NAME`, `GIT_EMAIL`, `MIN_PERL_VERSION`,
  `PROJECT_NAME`.
- **`cpan-maker`** replaces `make-cpan-dist.pl`; **`markdown-render`**
  replaces `md-utils.pl`; **`scandeps-static`** replaces
  `scandeps-static.pl`.
- **Dependency scanning** now produces three output tiers in a single
  scan pass: `requires`, `recommends`, `suggests` (via grouped make
  rule `requires.raw recommends.raw suggests.raw &:`).
- **`cpanfile`** generation now handles `requires`, `recommends`, and
  `suggests` as separate intermediate targets merged into the final
  file.
- **`deps.mk`** now depends on `.pm.in`/`.pl.in` source files rather
  than built `.pm`/`.pl` targets, eliminating the chicken-and-egg
  rebuild cycle on `make clean`.
- **`check-syntax`** is now a phony convenience alias; syntax checking
  is bundled into the `%.pm` / `%.pl` pattern rules.
- **`podchecker`** is now run as part of syntax checking for both
  `.pm` and `.pl` files.
- **`perlcritic`** now uses `--theme` and `--severity` flags
  (`PERLCRITIC_THEME`, `PERLCRITIC_SEVERITY`).
- **`CMB_VERSION_DRIFT`** — new configurable drift detection between
  the locally installed and locally used bootstrapper files (`fail` |
  `warn` | `ignore`).
- **`CMB_UPDATE_CHECK`** — new flag to enable/disable the CPAN version
  check for `CPAN::Maker::Bootstrapper` (`on` | `off`).
- **`extra-files.mk`** — new dynamically generated include that adds
  share-directory files as prerequisites of the distribution tarball.
- **`package`** target added — runs `clean` then rebuilds with `LINT=on SCAN=on`.
- **`repo`** target added — creates a new GitHub repository via `gha-aws`.
- **Docker `build-ci`** — the container now also bind-mounts the
  working directory; `INSTALLER` renamed to `DOCKER_CPAN_INSTALLER`.

---

## Upgrade Notes

- `--idle-threshold` has been **removed**. Use `--discovery-interval` instead.
- `--append` and `--format-messages` options have been **removed** from `aws-logs`.
- Run `make update` to pull the latest managed build files from your
  installed `CPAN::Maker::Bootstrapper`.
- Install `Date::Manip` to enable natural-language `--start-time` expressions beyond the compact `Nd`/`Nh`/`Nm` formats:
  ```
  cpanm Date::Manip
  ```
- Install `Cpanel::JSON::XS` for best performance with large CloudWatch log volumes:
  ```
  cpanm Cpanel::JSON::XS
  ```

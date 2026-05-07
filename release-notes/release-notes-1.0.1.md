# Amazon::CloudWatchLogs 1.0.1 Release Notes

## Overview

A bug-fix release resolving several issues with `get-stream` discovered
during real-world use: events not being returned despite the console
showing data, wide-character warnings on Unicode log output, and stream
ordering being non-deterministic due to hash key randomization. The build
system is also fully migrated to `CPAN::Maker::Bootstrapper`.

---

## Bug Fixes

**`get-stream` returned no events despite events existing in the console**

Three separate issues combined to produce this symptom:

*Cursor positioning.* `GetLogEvents` defaults to starting from the
**end** of a stream. `startTime` is a filter - it limits which events
are returned - but does not reposition the cursor. Without
`startFromHead: true`, the cursor was placed at the tail and paging
forward from the tail found nothing. `startFromHead: true` is now
passed on the initial request for each stream so the cursor is
positioned at the first event at or after `startTime`.

*`startTime` passed alongside `nextToken`.* On paginated requests, both
`startTime` and `nextToken` were being sent together. `nextToken` takes
exclusive control of cursor position once present; `startTime` is now
omitted from all requests where a token exists.

*Stream ordering non-deterministic.* Stream iteration order was
determined by Perl hash key ordering, which is randomized per process.
Both `%stream_tokens` and the hash returned by `fetch_streams` are now
tied to `Tie::IxHash` to preserve insertion order throughout.

**`descending => true` and explicit sort removed from `fetch_streams`**

`DescribeLogStreams` returns streams in ascending order by
`LastEventTime` by default - this is documented API behaviour. The
`descending => JSON::PP::true` option and the subsequent `reverse sort`
were added based on an incorrect assumption that the default order was
non-deterministic. In reality the hash randomization was making the
order appear unpredictable. Both are removed; the API-provided ascending
order is used directly.

**Wide character warning in `printf`**

`binmode STDOUT, ':utf8'` is now set before the event output loop,
suppressing `Wide character in printf` warnings when log events contain
Unicode.

---

## New Features

**`version` command and `--version|-v` flag**

`aws-logs --version` (or `aws-logs version`) prints the wrapper name
and version. `MODULINO_WRAPPER` is set in `bin/aws-logs.in` so the
version command can display the correct script name regardless of how
the modulino is invoked.

---

## Build System

**Fully migrated to `CPAN::Maker::Bootstrapper`**

The Makefile is rewritten with the full Bootstrapper-managed structure
and `.includes/` for managed targets:

| Include | Added |
|---|---|
| `perl.mk` | perltidy, perlcritic, syntax checking, pattern rules |
| `git.mk` | `make git` for initial repo commit |
| `help.mk` | `make help` from `##` comments |
| `release-notes.mk` | moved from project root; `LAST_TAG` override added |
| `update.mk` | `make update`, `make update-available` |
| `upgrade.mk` | `make upgrade`, `make check-upgrade` |
| `version.mk` | moved from project root; `## help` annotations added |

`make workflow`, `make build-ci`, `make test`, `make check`, `make
quick`, `make tidy`, `make critic`, `make lint` are all available. See
the `CPAN::Maker::Bootstrapper` documentation for details.

**`bin/aws-logs` converted to `bin/aws-logs.in` template**

The script is now a `.in` template processed at build time, consistent
with other `bin/` files. `MODULINO_WRAPPER` is set for the version
command.

**`buildspec.yml` normalized**

Underscore-style keys updated to canonical hyphenated forms:
`pm_module` → `pm-module`, `test_requires` → `test-requires`,
`pm_module` → `pm-module`, `exe_files` → `exe-files`.

**`cpanfile` added**

Generated from `requires` and `test-requires`. `Tie::IxHash 1.23` added
to `requires`.

**`release-notes/` directory**

Historical release notes moved from the project root into
`release-notes/`.

**`README.md` - table of contents added**

---

## Dependencies

**Added:** `Tie::IxHash 1.23`

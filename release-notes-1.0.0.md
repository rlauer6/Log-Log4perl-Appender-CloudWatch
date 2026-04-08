# Amazon::CloudWatchLogs 1.0.0 Release Notes

**Release Date:** 2026-04-08

## Overview

Initial release of `Amazon::CloudWatchLogs`, a command-line interface
for AWS CloudWatch Logs distributed as part of the
`Log::Log4perl::Appender::CloudWatch` distribution. The `aws-logs`
script provides a feature-complete alternative to the Python `awslogs`
tool with several significant improvements.

---

## Commands

### `get-stream`

Retrieves log events from one or more CloudWatch log streams matching
a group and optional stream name prefix.

**Follow mode** (`--follow|-f`) is the standout feature - unlike the
Python `awslogs` tool, `aws-logs` correctly handles multiple streams
simultaneously and automatically discovers new streams as they are
created. This makes it genuinely useful for monitoring ECS services,
Lambda functions, or any workload that creates a new log stream per
invocation.

Key behaviors in follow mode:

- All matching streams are polled concurrently on each iteration
- After `--idle-threshold` consecutive idle polls (default: 10),
  `fetch_streams` is called to discover newly created streams and
  merge them into the active poll set
- If no matching streams exist at startup, the script waits for
  streams to appear rather than exiting with an error
- Graceful `SIGINT` handling - Ctrl-C exits cleanly
- Poll interval is configurable via `--sleep-time` (default: 1s)

### `list-groups`

Lists all log groups in a tabular format showing group name, stored
bytes, and creation date.

### `list-streams`

Lists all log streams for a group in a tabular format showing stream
name, stored bytes, creation date, and last event timestamp.

### `create-group`

Creates a new log group.

### `create-stream`

Creates a new log stream with a unique MD5/UUID suffix appended to
the provided stream name prefix.

### `delete-group`

Deletes a log group.

### `last-stream`

Displays the most recently active log stream matching an optional
stream name prefix. Useful in CI/CD pipelines to retrieve the stream
name for a just-completed job.

---

## Options

- `--follow|-f` - tail mode with automatic new stream discovery
- `--start-time|-t` - filter events and streams by time
- `--idle-threshold` - number of idle polls before checking for new
  streams (default: 10)
- `--sleep-time` - poll interval in seconds (default: 1)
- `--limit|-L` - maximum number of streams to consider
- `--color|-c` - colorized group and stream name prefixes
- `--no-group-name|-G` - suppress group name in output
- `--no-stream-name|-S` - suppress stream name in output
- `--localstack|-l` - shorthand for LocalStack endpoint
- `--profile|-p` - AWS profile name
- `--region|-r` - AWS region

---

## Start Time Parsing

The `--start-time` option accepts `{n}d`, `{n}h`, `{n}m` for simple
relative times. If `Date::Manip` is installed, natural language
formats are also supported:

```
'2 days ago'
'yesterday'
'a week ago'
'last Tuesday'
'2026-04-08 10:00'
```

`Date::Manip` is an optional dependency - the script falls back to
the simple format parser if it is not installed.

---

## Comparison with `awslogs`

| Feature | `aws-logs` | `awslogs` |
|---------|-----------|---------|
| Follow mode | ✅ | ✅ |
| Discovers new streams in follow mode | ✅ | ❌ |
| Multiple streams polled simultaneously | ✅ | ❌ |
| Waits for streams to appear | ✅ | ❌ |
| Natural language time parsing | ✅ (optional) | ✅ |
| LocalStack support | ✅ | ✅ |
| Color output | ✅ | ✅ |
| Tabular group/stream listing | ✅ | ✅ |
| Active maintenance | ✅ | ❌ |
| Python dependency | ❌ | ✅ |

---

## Dependencies

- `Amazon::API` >= 2.2.0
- `Amazon::Credentials`
- `CLI::Simple`
- `Data::UUID`
- `Digest::MD5`
- `Number::Bytes::Human`
- `Text::ASCIITable`
- `Term::ANSIColor`
- `Time::HiRes`
- `Date::Format`
- `Date::Manip` (optional - enhanced time parsing)

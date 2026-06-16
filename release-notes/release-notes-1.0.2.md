# Release Notes - Amazon::CloudWatchLogs 1.0.2

## Bug Fixes

### `fetch_streams` - Fixed `decode_always` flag not preserved across calls

`fetch_streams` now saves and restores the `decode_always` flag on the
`Amazon::API` client before calling `DescribeLogStreams`. Previously, when
`fetch_streams` was called from within the `--follow` polling loop (after
`cmd_get_stream` had set `decode_always` to false for performance), the
`DescribeLogStreams` response was returned as a raw JSON string rather than a
decoded hashref, causing a fatal `Can't use string as HASH ref` error under
`strict refs`.

### `fetch_streams` - Stream pre-filter too aggressive for infrequent log streams

The `lastIngestionTime` filter that excluded streams older than `--start-time`
was discarding all streams when the most recent Lambda invocation fell just
outside the requested window (e.g. `-t '10 minutes ago'` when the last
invocation was 12 minutes ago). `fetch_streams` now falls back to the full
stream list when the filter produces no results, allowing `GetLogEvents` with
`startTime` to handle event filtering correctly on the AWS side.

### `cmd_get_stream` - `decode_always` flag not restored on exit

`cmd_get_stream` now saves the `decode_always` flag before setting it to false
and restores it after the `FOLLOW` loop completes, preventing subsequent calls
(e.g. `fetch_streams` during idle threshold checks) from operating with stale
flag state.

## Performance Improvements

### JSON backend - `JSON::PP` replaced with `JSON`

`JSON::PP` has been replaced with `JSON`, which selects the fastest available
XS backend automatically via `PERL_JSON_BACKEND`:

```perl
BEGIN {
  $ENV{PERL_JSON_BACKEND} = 'Cpanel::JSON::XS,JSON::XS,JSON::PP';
  use JSON qw(decode_json encode_json);
}
```

On large `GetLogEvents` payloads (~2MB), `Cpanel::JSON::XS` decodes in under
0.1 seconds vs ~4 seconds for `JSON::PP`. Installing `Cpanel::JSON::XS` is
strongly recommended. Combined with the existing `decode_always` optimization
in `cmd_get_stream`, total retrieval time for ~9,500 events drops from ~8
seconds to under 0.5 seconds per page.

## Other Changes

### Dependencies updated to `CLI::Simple` 2.0.1

Requires `CLI::Simple`, `CLI::Simple::Constants`, and `CLI::Simple::Utils`
2.0.1. `CLI::Simple::Utils` is a new direct dependency, used for the `choose`
utility in `cmd_get_stream`.

### Lazy loading of optional modules

`Text::ASCIITable`, `Number::Bytes::Human`, and `Term::ANSIColor` are now
loaded on demand rather than at startup, reducing load time when those features
are not used.

### POD significantly expanded

Documentation now covers all commands with examples, all options with
descriptions, start time formats, follow mode polling behavior, performance
rationale (JSON backend selection, shape deserialization bypass), dependency
recommendations, and benchmarks comparing `aws-logs` to the AWS CLI.

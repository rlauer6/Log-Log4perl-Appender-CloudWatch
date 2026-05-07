# Table of Contents

* [NAME](#name)
* [SYNOPSIS](#synopsis)
* [DESCRIPTION](#description)
* [DEPENDENCIES](#dependencies)
* [CONFIGURATION](#configuration)
  * [Options](#options)
* [CAVEATS](#caveats)
* [SEE ALSO](#see-also)
* [AUTHOR](#author)
* [LICENSE](#license)
# NAME

Log::Log4perl::Appender::CloudWatch - Appender to send logs to CloudWatch

# SYNOPSIS

    use Log::Log4perl;

    my $log4perl_conf =<<'END_OF_TEXT';
    log4perl.rootLogger=DEBUG, CLOUDWATCH
    log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch
    log4perl.appender.CLOUDWATCH.group=/test-log-group
    log4perl.appender.CLOUDWATCH.stream=stream-prefix
    log4perl.appender.CLOUDWATCH.buffer_size=1
    log4perl.appender.CLOUDWATCH.layout=PatternLayout
    log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m
    END_OF_TEXT

    Log::Log4perl::init(\$log4perl_conf);

    my $logger = Log::Log4perl->get_logger('');

# DESCRIPTION

Appender to send logs to AWS CloudWatch. Events are buffered and sent
when the buffer is full or when the appender is destroyed.

# DEPENDENCIES

    Amazon::API
    Amazon::Credentials
    Data::UUID
    Digest::MD5

...and possibly others

# CONFIGURATION

The appender supports several configuration attributes for logging to
CloudWatch described below.

Example Log::Log4perl configuration:

    ############################################################
    # A simple root logger with a Log::Log4perl::Appender::CloudWatch 
    ############################################################
    log4perl.rootLogger=DEBUG, CLOUDWATCH

    log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch
    log4perl.appender.CLOUDWATCH.group=/test-log-group
    log4perl.appender.CLOUDWATCH.stream=foobar

    log4perl.appender.CLOUDWATCH.layout=PatternLayout
    log4perl.appender.CLOUDWATCH.layout.ConversionPattern=%d [%r] %F %L %c - %m

## Options

- group (required)
    - name

        Name of the log group where log streams will be written

    - mode

        Determines if the log group should be created if it does not exist.

        valid values: create

        _Note: You can use the dot notation or just set `group` to the group name._

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch
            log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
            log4perl.appender.CLOUDWATCH.stream.mode=create
- stream (optional)
    - name

        Name of the stream. The name of the stream is used as a prefix unless
        the `mode` option is set to 'append'.  If no stream name is given,
        then a unique stream name will be created composed of the log group
        name and a unique suffix.

    - mode

        If mode is set to 'append' the appender will append logs to the
        group/stream provided.  If no mode is provided or the mode is set to
        'create' then a new stream will be created. The appender will use the
        stream name as a prefix with a suffix consisting of the MD5 hash of a
        UUID in order to create a unique stream name.

        Example:

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch
            log4perl.appender.CLOUDWATCH.group=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream=

            stream name = ecs/myapp/f974195a83b143a68672b62457a313ca

        valid values: append|create

        _Note: You can use the dot notation or just set `stream` to the stream name._

            log4perl.appender.CLOUDWATCH=Log::Log4perl::Appender::CloudWatch
            log4perl.appender.CLOUDWATCH.group.name=/ecs/myapp
            log4perl.appender.CLOUDWATCH.stream.name=ecs/myapp/2026-04-06
            log4perl.appender.CLOUDWATCH.stream.mode=create
- buffer\_size

    The number of events to buffer before sending the events to
    CloudWatch. The maximum number of events that can sent in one payload
    is 10K. The maximum size of the payload is 1,048,576 bytes.

    default: 1000

    See
    [https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API\_PutLogEvents.html](https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html)
    for more details.

- max\_retries

    The number of times to retry the PutLogEvents operation if an
    `Amazon::API::Error` exception is thrown.

    default: 5

- retry\_delay

    The amount of time (in seconds) to wait before retrying the
    PutLogEvents operation.

    default: 1

- endpoint\_url

    The API endpoint - leave blank for AWS, http://localhost:4566 for
    LocalStack (or where you have installed LocalStack).

# CAVEATS

The appender internally uses a null logger to prevent re-entrant
logging calls. Any debugging of the CloudWatch API calls made
internally by the appender should be done outside the context of
this appender - for example, in a standalone test script that
invokes `Amazon::API::CloudWatchLogs` directly rather than through
Log::Log4perl configuration.

# SEE ALSO

[Amazon::API::CloudWatchLogs](https://metacpan.org/pod/Amazon%3A%3AAPI%3A%3ACloudWatchLogs), [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials), [Amazon::API](https://metacpan.org/pod/Amazon%3A%3AAPI)

# AUTHOR

Rob Lauer - <rlauer6@comcast.net>

# LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

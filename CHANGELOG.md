# Changelog

## 0.4.3
 - Bumped `json` and `logstash-core-plugin-api` for compatibility with logstash 8.X
 - Removed deprecated secret option in the sentry configuration

## 0.4.2
 - Fix string templating for key, url, secret and project_id fields

## 0.4.1
 - Fixing versions for development dependencies.

## 0.4.0
 - Implements the full sentry interface.

## 0.2.0
 - Improving sentry.rb script based on antho31/logstash-output-sentry and bigpandaio/logstash-output-sentry projects.
 - Creating documentation (starting from bigpandaio/logstash-output-sentry with some fixes for the differences that we have introduced to the code).

## 0.1.0
 - Starting project from clarkdave/logstash-sentry.rb.
 - Packing script in a gem so it can be easily installed.
 - Adding parameters so that we can use the plugin to send data to our own sentry server.

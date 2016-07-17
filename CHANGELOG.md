## 0.4.0
 - Update version of Sentry protocol to '7'
 - Add possibility for custom fields to tags via `fields_to_tags`
 - Add `fingerprint`, `release`, `environment` attributes
 - Be careful. Old parameter `fields_to_tags` was renamed to `all_fields_to_tags`
## 0.2.0
 - Improving sentry.rb script based on antho31/logstash-output-sentry and bigpandaio/logstash-output-sentry projects.
 - Creating documentation (starting from bigpandaio/logstash-output-sentry with some fixes for the differences that we have introduced to the code).
## 0.1.0
 - Starting project from clarkdave/logstash-sentry.rb
 - Packing script in a gem so it can be easily installed.
 - Adding parameters so that we can use the plugin to send data to our own sentry server.

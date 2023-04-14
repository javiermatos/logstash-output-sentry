# Logstash-Output-Sentry Plugin

This is a plugin for [Logstash](https://github.com/elasticsearch/logstash).

This plugin gives you the possibility to send your output parsed with Logstash to a Sentry host.

This plugin is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

But keep in mind that this is not an official plugin, and this plugin is not supported by the Logstash community.


## Documentation

### Installation

You must have [Logstash](https://github.com/elasticsearch/logstash) installed for using this plugin. You can find instructions on how to install it on the [Logstash website](https://www.elastic.co/downloads/logstash). Maybe the easiest way to install is using their [repositories](https://www.elastic.co/guide/en/logstash/current/package-repositories.html).

As this plugin has been shared on [RubyGems](https://rubygems.org) with the name [logstash-output-sentry](https://rubygems.org/gems/logstash-output-sentry) you can install it using the following command from your Logstash installation path:

```sh
bin/logstash-plugin install logstash-output-sentry
```

When installing from official repository as suggested below, the installation path is `/opt/logstash`.

### Usage

[Sentry](https://getsentry.com/) is a modern error logging and aggregation platform.
It's important to note that Sentry should not be thought of as a log stream, but as an aggregator.
It fits somewhere in-between a simple metrics solution (such as Graphite) and a full-on log stream aggregator (like Logstash).

* In Sentry, generate and get your client key (Settings -> Client Keys (DSN)). The client key has this form:
```
[http|https]://[key]@[host]/[project_id]
```

* Setup logstash to write to sentry:
```ruby
output {
  sentry {
    'key' => "yourkey"
    'project_id' => "yourprojectid"
  }
}
```

* By default, the plugin connects to https://app.getsentry.com/api. Set the `url` if you have installed Sentry on your own machine:
```ruby
output {
  sentry {
    'url' => "http://local.sentry:9000/api"
    'key' => "yourkey"
    'project_id' => "yourprojectid"
  }
}
```

* If you don't configure anything else, the necessary fields will be set automatically, i.e., `event_id`, `timestamp` (set to `@timestamp`), `logger` (set to `"logstash"`) and `platform` (set to `"other"`). All the other fields from logstash are going to be put into the `extra` field in sentry. Additionally, the `level` is set to `"error"` and the `server_name` to the value of `host`.

* The plugin can write to all the fields that the sentry interface currently supports, i.e., `timestamp`, `message`, `logger`, `platform`, `sdk`, `level`, `culprit`, `server_name`, `release`, `tags`, `environment`, `modules`, `extra`, `fingerprint`, `exception`, `sentry.interface.Message`, `stacktrace`, `template`, `breadcrumbs`, `contexts`, `request`, `threads`, `user`, `debug_meta`, `repos`, `sdk`. To set a field, you can either read the value from another field or set it to a constant value by setting the corresponding `_value`:
```ruby
output {
  sentry {
    'message' => "message" # sets message to the contents of the message field
    'environment' => "[tag][Environment]" # sets message to the contents of the field Environment in tag
    'exception' => "[@metadata][sentry][exception]" # sets exception to the metadata field, see below for a complete example
    'user_value' => "nobody" # sets the user to the constant "nobody"

    'key' => "yourkey"
    'project_id' => "yourprojectid"
  }
}
```

* You can also prepare the settings in a filter to create a cleaner config:
```ruby
input {
  syslog {
    port => 514
    type => "syslog"
  }

  tcp {
    port => 1514
    type => "cisco-ios"
  }

  tcp {
    port => 2514
    type => "application"
  }
}
filter {
  if [type] == "syslog" {
    mutate {
      add_field => {
        "[@metadata][sentry][msg]"      => "%{host}"
        "[@metadata][sentry][severity]" => "%{severity}"
        "[@metadata][sentry][host]"     => "192.168.1.101"
        "[@metadata][sentry][pid]"      => "2"
        "[@metadata][sentry][key]"      => "d3921923d34a4344878f7b83e2061229"
      }
    }
  }
  else if [type] == "cisco-ios" {
    mutate {
      add_field => {
        "[@metadata][sentry][msg]"      => "%{host}"
        "[@metadata][sentry][severity]" => "%{severity}"
        "[@metadata][sentry][host]"     => "192.168.1.101"
        "[@metadata][sentry][pid]"      => "3"
        "[@metadata][sentry][key]"      => "d398098q2349883e206178098"
      }
    }
  }
  else if [type] == "application" {
    mutate {
      add_field => {
        "[@metadata][sentry][msg]"      => "%{host}"
        "[@metadata][sentry][severity]" => "%{severity}"
        "[@metadata][sentry][host]"     => "192.168.1.150"
        "[@metadata][sentry][pid]"      => "4"
        "[@metadata][sentry][key]"      => "d39dc435326d987d5678e98d76cf78098"
      }
    }
  }
}
output {
  sentry {
    server_name => "[@metadata][sentry][host]"
    level => "[@metadata][sentry][severity]"
    message => "[@metadata][sentry][msg]"

    project_id     => "%{[@metadata][sentry][pid]}"
    key            => "%{[@metadata][sentry][key]}"
  }
}
```

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Note that this plugin has been written from [this Gist](https://gist.github.com/clarkdave/edaab9be9eaa9bf1ee5f).

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
bin/plugin install logstash-output-sentry
```

When installing from official repository as suggested below, the installation path is `/opt/logstash`.

### Usage

[Sentry](https://getsentry.com/) is a modern error logging and aggregation platform.
It's important to note that Sentry should not be thought of as a log stream, but as an aggregator.
It fits somewhere in-between a simple metrics solution (such as Graphite) and a full-on log stream aggregator (like Logstash).

* In Sentry, generate and get your client key (Settings -> Client key). The client key has this form:
```
[http|https]://[key]:[secret]@[host]/[project_id]
```

* In your Logstash configuration file, inform your client key:
```ruby
output {
  sentry {
    'key' => "yourkey"
    'secret' => "yoursecretkey"
    'project_id' => "yourprojectid"
  }
}
```

* Note that all your fields (incluing the Logstash field `message`) will be in the `extra` field in Sentry. But be careful: by default, the `host` is set to `"app.getsentry.com"`. If you have installed Sentry on your own machine, please change the `host` (change "localhost:9000" with the correct value according your configuration):
```ruby
output {
  sentry {
    'host' => "localhost:9000"
    'use_ssl' => false
    'project_id' => "yourprojectid"
    'key' => "yourkey"
    'secret' => "yoursecretkey"
  }
}
```

* You can change the `message` field (default: `"Message from logstash"`), or optionally specify a field to use from your event. In case the `message` field doesn't exist, it'll be used as the actual message.
```ruby
sentry {
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "msg_field"
}
```

* You can indicate the level (default: `"error"`), and decide if all your Logstash fields will be tagged in Sentry. If you use the protocole HTTPS, please enable `use_ssl` (default: `true`), but if you use http you MUST disable SSL.
```ruby
sentry {
  'host' => "192.168.56.102:9000"
  'use_ssl' => false
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "Message you want"
  'level_tag' => "fatal"
  'all_fields_to_tags' => true
}
```

* You can optionally strip the timestamp from the sentry title by setting `strip_timestamp` field to `true` (default: `false`), which will change `YYYY-MM-DD HH:MM:SS,MILLISEC INFO ..` to `INFO ...`
```ruby
sentry {
  'host' => "192.168.56.102:9000"
  'use_ssl' => false
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "Message you want"
  'level_tag' => "fatal"
  'all_fields_to_tags' => true
  'strim_timestamp' => true
}
```
* You can control event collation in Sentry via `fingerprint` option. [See more](https://docs.getsentry.com/hosted/learn/rollups/#custom-grouping).
```ruby
output {
  sentry {
    'host' => "localhost:9000"
    'use_ssl' => false
    'project_id' => "yourprojectid"
    'key' => "yourkey"
    'secret' => "yoursecretkey"
    'fingerprint' => ["%{traceback_id_field_from_event}","static_field"]
  }
}
```

* You can also set the project id, key, level tag, and secret in a filter to allow for a cleaner dynamic config
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
        "[@metadata][sentry][secret]"   => "d0163ef306c04148aee49fe4ce7621b1"
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
        "[@metadata][sentry][secret]"   => "da098d890f098d09809f6098c87e0"
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
        "[@metadata][sentry][secret]"   => "07d09876d543d2a345e43c4e567d"
      }
    }
  }
}
output {
  elasticsearch {
    hosts          => ["192.168.1.200:9200"]
    document_type  => "%{type}"
  }
  sentry {
    fields_to_tags => ["user", "type"]
    host           => "%{[@metadata][sentry][host]}"
    key            => "%{[@metadata][sentry][key]}"
    level_tag      => "%{[@metadata][sentry][severity]}"
    msg            => "[@metadata][sentry][msg]"
    project_id     => "%{[@metadata][sentry][pid]}"
    secret         => "%{[@metadata][sentry][secret]}"
  }
}
```

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Note that this plugin has been written from [this Dave Clark's Gist](https://gist.github.com/clarkdave/edaab9be9eaa9bf1ee5f).

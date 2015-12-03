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

When installing from official repository as suggested below, the installation path is ```/opt/logstash```.

### Usage

[Sentry](https://getsentry.com/) is a modern error logging and aggregation platform.
It’s important to note that Sentry should not be thought of as a log stream, but as an aggregator.
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

* Note that all your fields (incluing the Logstash field "message") will be in the "extra" field in Sentry. But be careful : by default , the host is set to "app.getsentry.com". If you have installed Sentry on your own machine, please change the host (change "localhost:9000" with the correct value according your configuration):
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

* You can change the "message" field (default : "Message from logstash"), or optionally specify a field to use from your event. In case the message field doesn't exist, it'll be used as the actual message.
```ruby
sentry {
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "msg_field"
}
```

* You can indicate the level (default : "error"), and decide if all your Logstash fields will be tagged in Sentry. If you use the protocole HTTPS, please enable "use_ssl" (default : true), but if you use http you MUST disable ssl.
```ruby
sentry {
  'host' => "192.168.56.102:9000"
  'use_ssl' => false
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "Message you want"
  'level_tag' => "fatal"
  'fields_to_tags' => true
}
```

* You can optionally strip the timestamp from the sentry title by do setting `strip_timestamp` to `true`, which will change `YYYY-MM-DD HH:MM:SS,MILLISEC INFO ..` to `INFO ...`
```ruby
sentry {
  'host' => "192.168.56.102:9000"
  'use_ssl' => false
  'project_id' => "1"
  'key' => "87e60914d35a4394a69acc3b6d15d061"
  'secret' => "596d005d20274474991a2fb8c33040b8"
  'msg' => "Message you want"
  'level_tag' => "fatal"
  'fields_to_tags' => true
  'strim_timestamp' => true
}
```

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Note that this plugin has been written from [this Dave Clark's Gist](https://gist.github.com/clarkdave/edaab9be9eaa9bf1ee5f).

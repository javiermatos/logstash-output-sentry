# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'securerandom'
require 'net/https'
require 'uri'
require 'json'

# Sentry is a modern error logging and aggregation platform.
# * https://getsentry.com/
#
# It’s important to note that Sentry should not be thought of as a log stream, but as an aggregator.
# It fits somewhere in-between a simple metrics solution (such as Graphite) and a full-on log stream aggregator (like Logstash).
#
# Generate and inform your client key (Settings -> Client key)
# The client key has this form  * https://[key]:[secret]@[host]/[project_id] *
#
# More informations :
# * https://sentry.readthedocs.org/en/latest/


class LogStash::Outputs::Sentry < LogStash::Outputs::Base

  config_name 'sentry'

  # Whether to use SSL (https) or not (http)
  config :use_ssl, :validate => :boolean, :required => false, :default => true

  # Sentry host
  config :host, :validate => :string, :required => true, :default => 'app.getsentry.com'

  # Project id, key and secret
  config :project_id, :validate => :string, :required => true
  config :key, :validate => :string, :required => true
  config :secret, :validate => :string, :required => true

  # This sets the message value in Sentry (the title of your event)
  config :msg, :validate => :string, :default => 'Message from logstash', :required => false

  # This sets the server_name value in Sentry (the host of your event)
  # Order of detection: event[your_specified] -> event[host] -> "no_server_name"
  config :server_name, :validate => :string, :default => 'host', :required => false

  # This sets the level value in Sentry (the level tag), allow usage of event dynamic value
  config :level_tag, :validate => :string, :default => 'error'

  # If set to true automatically map all logstash defined fields to Sentry extra fields.
  # As an example, the logstash event:
  # [source,ruby]
  #    {
  #      "@timestamp": "2013-12-10T14:36:26.151+0000",
  #      "@version": 1,
  #      "message": "log message",
  #      "host": "host.domain.com",
  #      "nested_field": {
  #                        "key": "value"
  #                      }
  #    }
  # Is mapped to this Sentry  event:
  # [source,ruby]
  # tags {
  #      "@timestamp": "2013-12-10T14:36:26.151+0000",
  #      "@version": 1,
  #      "message": "log message",
  #      "host": "host.domain.com",
  #      "nested_field": {
  #                        "key": "value"
  #                      }
  #    }
  config :all_fields_to_tags, :validate => :boolean, :default => false, :required => false

  # Fields from this array will be mapped to tags in Sentry event. It will be overwrited by 'all_fields_to_tags'
  # As an example, the logstash event:
  # [source,ruby]
  #    {
  #      "@timestamp": "2013-12-10T14:36:26.151+0000",
  #      "@version": 1,
  #      "message": "log message",
  #      "host": "host.domain.com",
  #      "nested_field": {
  #                        "key": "value"
  #                      }
  #    }
  # Is mapped to this Sentry  event with 'fields_to_tags: [nested_field]' :
  # [source,ruby]
  # tags {
  #      "nested_field": {
  #                        "key": "value"
  #                      }
  #    }
  config :fields_to_tags, :validate => :array, :default => [], :required => false

  # Remove timestamp from message (title) if the message starts with a timestamp
  config :strip_timestamp, :validate => :boolean, :default => false, :required => false

  # Optional Release attribute for Sentry event.
  # His value will generally be something along the lines of the git SHA for the given project.
  config :release, :validate => :string, :default => "", :required => false

  # The environment name, such as ‘production’ or ‘staging’.
  config :environment, :validate => :string, :default => "", :required => false

  # Fingerprint. Sentry events will be collated by this field. Server must support version Protocol ‘7’.
  # More info: https://docs.getsentry.com/hosted/learn/rollups/#custom-grouping
  config :fingerprint, :validate => :array, :default => ['{{ default }}'], :required => false

  public
  def register
    @logger.info('Sentry output has been started successfully')
  end

  public
  def receive(event)
    url = "%{proto}://#{event.sprintf(@host)}/api/#{event.sprintf(@project_id)}/store/" % { :proto => use_ssl ? 'https' : 'http' }
    uri = URI.parse(url)

    client = Net::HTTP.new(uri.host, uri.port)
    client.use_ssl = use_ssl
    client.verify_mode = OpenSSL::SSL::VERIFY_NONE

    @logger.debug('Client', :client => client.inspect)

    return unless output?(event)

    #use message from event if exists, if not from static
    message_to_send = event["#{@msg}"] || "#{@msg}"
    if strip_timestamp
      #remove timestamp from message if available
      message_matched = message_to_send.match(/\d\d\d\d\-\d\d\-\d\d\s[0-9]{1,2}\:\d\d\:\d\d,\d{1,}\s(.*)/)
      message_to_send = message_matched ? message_matched[1] : message_to_send
    end

    packet = {
      :event_id    => SecureRandom.uuid.gsub('-', ''),
      :timestamp   => event['@timestamp'],
      :message     => message_to_send,
      :level       => event.sprintf(@level_tag),
      :platform    => 'other',
      :sdk         => {
        :version => "0.4.0",
        :name    => "raven_logstash"
      },
      :server_name => event[@server_name] || event['host'] || "no_server_name",
      :extra       => event.to_hash,
    }
    packet[:release] = event.sprintf(@release) unless release.empty?
    packet[:environment] = event.sprintf(@environment) unless environment.empty?

    if all_fields_to_tags
      packet[:tags] = event.to_hash
    elsif not fields_to_tags.empty?
      packet[:tags] = {}
      fields_to_tags.each do |f|
        if event.to_hash.key?(f)
          packet[:tags][f] = event[f]
        end
      end
    end
    packet[:fingerprint] = []
    @fingerprint.each do |fp|
      packet[:fingerprint] << event.sprintf(fp)
    end

    @logger.debug('Sentry packet', :sentry_packet => packet)

    auth_header = "Sentry sentry_version=7," +
      "sentry_client=raven_logstash/0.4.0," +
      "sentry_timestamp=#{event['@timestamp'].to_i}," +
      "sentry_key=#{event.sprintf(@key)}," +
      "sentry_secret=#{event.sprintf(@secret)}"

      request = Net::HTTP::Post.new(uri.path)

    begin
      request.body = packet.to_json
      request.add_field('X-Sentry-Auth', auth_header)

      response = client.request(request)

      @logger.info('Sentry response', :request => request.inspect, :response => response.inspect)

      raise unless response.code == '200'
    rescue Exception => e
      @logger.warn('Unhandled exception', :request => request.inspect, :response => response.inspect, :exception => e.inspect)
    end
  end
end

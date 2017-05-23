# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'json'

class LogStash::Outputs::Sentry < LogStash::Outputs::Base
  config_name 'sentry'
  concurrency :shared

  # Sentry API URL
  config :url, :validate => :uri, :required => false, :default => 'https://app.getsentry.com/api'

  # Project id, key and secret
  config :project_id, :validate => :string, :required => true
  config :key, :validate => :string, :required => true
  config :secret, :validate => :string, :required => true

  def self.sentry_key(name, field_default=nil, value_default=nil)
    name = name.to_s if name.is_a?(Symbol)

    @sentry_keys ||= []
    @sentry_keys << name

    opts = {
        :validate => :string,
        :required => false,
    }

    config name, opts.merge(if field_default then {:default => field_default} else {} end)
    config "#{name}_value", opts.merge(if value_default then {:default => value_default} else {} end)
  end
  class << self; attr_accessor :sentry_keys end
  # https://docs.sentry.io/clientdev/attributes/
  sentry_key :timestamp, field_default='@timestamp'
  sentry_key :message
  sentry_key :_logger
  sentry_key :platform
  sentry_key :sdk
  sentry_key :level, value_default='error'
  sentry_key :culprit
  sentry_key :server_name, field_default='host'
  sentry_key :release
  sentry_key :tags
  sentry_key :environment
  sentry_key :modules
  sentry_key :extra, field_default='' # puts all fields into extra
  sentry_key :fingerprint
  # https://docs.sentry.io/clientdev/interfaces/exception/
  sentry_key :exception
  # https://docs.sentry.io/clientdev/interfaces/message/
  sentry_key :"sentry.interfaces.Message"
  # https://docs.sentry.io/clientdev/interfaces/stacktrace/
  sentry_key :stacktrace
  # https://docs.sentry.io/clientdev/interfaces/template/
  sentry_key :template
  # https://docs.sentry.io/clientdev/interfaces/breadcrumbs/
  sentry_key :breadcrumbs
  # https://docs.sentry.io/clientdev/interfaces/contexts/
  sentry_key :contexts
  # https://docs.sentry.io/clientdev/interfaces/http/
  sentry_key :request
  # https://docs.sentry.io/clientdev/interfaces/threads/
  sentry_key :threads
  # https://docs.sentry.io/clientdev/interfaces/user/
  sentry_key :user
  # https://docs.sentry.io/clientdev/interfaces/debug/
  sentry_key :debug_meta
  # https://docs.sentry.io/clientdev/interfaces/repos/
  sentry_key :repos
  # https://docs.sentry.io/clientdev/interfaces/sdk/
  sentry_key :sdk

  public
  def register
  end

  def get(event, key)
    key = key.to_s if key.is_a?(Symbol)

    instance_variable_name = key.gsub(/\./, '')

    field = instance_variable_get("@#{instance_variable_name}")
    if field == ''
      ret = event.to_hash
      ret.delete('tags')
      return ret
    elsif field
      return event.get(field) if event.get(field)
    end

    value = instance_variable_get("@#{instance_variable_name}_value")
    return value # can be nil
  end

  def multi_receive(events)
    for event in events
      receive(event)
    end
  end

  def create_packet(event, timestamp)
    require 'securerandom'
    event_id = SecureRandom.uuid.gsub('-', '')

    packet = {
      # parameters required by sentry
      :event_id => event_id,
      :timestamp => timestamp.to_s,
      :logger => get(event, :_logger) || "logstash",
      :platform => get(event, :platform) || "other",
    }

    for key in LogStash::Outputs::Sentry.sentry_keys
        sentry_key = key.gsub(/^_/,'')
        next if packet[sentry_key];
        value = get(event, key)
        packet[sentry_key] = value if value
    end

    return packet
  end

  def send_packet(event, packet, timestamp)
    auth_header = "Sentry sentry_version=5," +
      "sentry_client=raven_logstash/0.4.0," +
      "sentry_timestamp=#{timestamp.to_i}," +
      "sentry_key=#{@key}," +
      "sentry_secret=#{@secret}"

    url = "#{@url}/#{@project_id}/store/"

    require 'http'
    response = HTTP.post(url, :body => packet.to_json, :headers => {:"X-Sentry-Auth" => auth_header})
    raise "Sentry answered with #{response} and code #{response.code} to our request #{packet}" unless response.code == 200
  end

  def receive(event)
    begin
      require 'time'
      timestamp = get(event, :timestamp) || Time.now

      sentry_packet = create_packet(event, timestamp)
      @logger.debug('Sentry packet', :sentry_packet => sentry_packet)
                   
      send_packet(event, sentry_packet, timestamp)
    rescue Exception => e
      @logger.warn('Unhandled exception', :exception => e)
    end
  end
end

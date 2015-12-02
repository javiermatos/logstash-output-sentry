# encoding: utf-8
# The MIT License (MIT)

# Copyright (c) 2014 Dave Clark

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'logstash/outputs/base'
require 'logstash/namespace'

class LogStash::Outputs::Sentry < LogStash::Outputs::Base

  config_name 'sentry'

  config :host, :validate => :string, :required => true, :default => 'app.getsentry.com'
  config :use_ssl, :validate => :boolean, :required => false, :default => true
  config :key, :validate => :string, :required => true
  config :secret, :validate => :string, :required => true
  config :project_id, :validate => :string, :required => true

  public
  def register
    require 'net/https'
    require 'uri'
    
    @url = "%{proto}://#{host}/api/#{project_id}/store/" % { :proto => use_ssl ? 'https' : 'http' }
    @uri = URI.parse(@url)
    @client = Net::HTTP.new(@uri.host, @uri.port)
    @client.use_ssl = use_ssl
    @client.verify_mode = OpenSSL::SSL::VERIFY_NONE

    @logger.debug('Client', :client => @client.inspect)
  end

  public
  def receive(event)
    return unless output?(event)

    require 'json'
    require 'securerandom'

    packet = {
      :event_id => SecureRandom.uuid.gsub('-', ''),
      :timestamp => event['@timestamp'],
      :message => event['message']
    }

    packet[:level] = event['[fields][level]']

    packet[:platform] = 'logstash'
    packet[:server_name] = event['host']
    #packet[:extra] = event['fields'].to_hash

    @logger.debug('Sentry packet', :sentry_packet => packet)

    auth_header = "Sentry sentry_version=5," +
      "sentry_client=raven_logstash/1.0," +
      "sentry_timestamp=#{event['@timestamp'].to_i}," +
      "sentry_key=#{@key}," +
      "sentry_secret=#{@secret}"

    request = Net::HTTP::Post.new(@uri.path)

    begin
      request.body = packet.to_json
      request.add_field('X-Sentry-Auth', auth_header)

      response = @client.request(request)

      @logger.info('Sentry response', :request => request.inspect, :response => response.inspect)

      raise unless response.code == '200'
    rescue Exception => e
      @logger.warn('Unhandled exception', :request => request.inspect, :response => response.inspect, :exception => e.inspect)
    end
  end
end

Gem::Specification.new do |s|
  s.name = 'logstash-output-sentry'
  s.version = '0.4.0'
  s.licenses = ['Apache-2.0']
  s.summary = 'This output plugin sends messages to any sentry server.'
  s.description = 'This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install logstash-output-sentry. This gem is not a stand-alone program.'
  s.authors = ['Javier Matos Odut', 'Julian Rüth']
  s.email = 'iam@javiermatos.com'
  s.homepage = 'https://github.com/javiermatos/logstash-output-sentry'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { 'logstash_plugin' => 'true', 'logstash_group' => 'output' }

  # Gem dependencies
  s.add_runtime_dependency 'logstash-core-plugin-api', '>= 1.60', '< 3.0'
  s.add_runtime_dependency 'json', '>=1.8.0', '< 2.0.0'
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'logstash-codec-plain'
end

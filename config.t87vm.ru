# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

path = '/imits'
ENV['RAILS_RELATIVE_URL_ROOT'] = path

require ::File.expand_path('../config/application',  __FILE__)

Kermits2::Application.initialize!

run Rack::URLMap.new(
  path => Rails.application
)

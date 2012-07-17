# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

ENV['RAILS_RELATIVE_URL_ROOT'] = ENV['APP_RELATIVE_URL_ROOT']

require ::File.expand_path('../config/application', __FILE__)

Kermits2::Application.initialize!

run Rack::URLMap.new(
  ENV['APP_RELATIVE_URL_ROOT'] => Rails.application
)

# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

ENV['RAILS_RELATIVE_URL_ROOT'] = ENV['APP_RELATIVE_URL_ROOT']

require ::File.expand_path('../config/environment', __FILE__)

run Rack::URLMap.new(
  ENV['APP_RELATIVE_URL_ROOT'] => Rails.application
)

# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

require ::File.expand_path('../config/application',  __FILE__)

# Override logging locations when deployed to /opt/t87
logdir = Pathname.new('/opt/t87/local/logs/imits')
Kermits2::Application.configure do
  config.paths.log = logdir + "#{Rails.env}.log"
  config.paths.config.database = "/opt/t87/global/conf/imits/database.#{Rails.env}.yml"
end

Kermits2::Application.initialize!

run Rack::URLMap.new(
  '/imits' => Rails.application
)

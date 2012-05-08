# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

path = '/imits'
ENV['RAILS_RELATIVE_URL_ROOT'] = path

require ::File.expand_path('../config/application',  __FILE__)

# Override some locations when deployed to /opt/t87
logdir = Pathname.new('/opt/t87/local/logs/imits')
tmpdir = Pathname.new("/tmp/imits/#{Rails.env}")
FileUtils.mkdir_p tmpdir
Kermits2::Application.configure do
  config.paths.log = logdir + "#{Rails.env}.log"
  config.paths.config.database = "/opt/t87/global/conf/imits/database.#{Rails.env}.yml"
  config.paths.tmp = tmpdir
end

Kermits2::Application.initialize!

run Rack::URLMap.new(
  path => Rails.application
)

# Custom rackup script that prefixes application with a path and sends
# logs to VM-standard location

path = ENV['APP_RELATIVE_URL_ROOT']
ENV['RAILS_RELATIVE_URL_ROOT'] = path

require ::File.expand_path('../config/application',  __FILE__)

if File.dirname(File.expand_path(__FILE__)).match %r{^/opt/t87/global}
  T87VM = true
else
  T87VM = false
end

if T87VM
  Kermits2::Application.configure do
  # Override some locations when deployed to /opt/t87
  config.paths.log = "/opt/t87/local/logs/imits/#{Rails.env}/app.log"
  config.paths.config.database = "/opt/t87/global/conf/imits/#{Rails.env}/database.yml"

  tmppath = "/var/tmp/imits/#{Rails.env}"
  FileUtils.mkdir_p tmppath
  FileUtils.chown nil, 't87svc', tmppath
  FileUtils.chmod 2775, tmppath
  config.paths.tmp = tmppath
  end
end

Kermits2::Application.initialize!

run Rack::URLMap.new(
  path => Rails.application
)

require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Kermits2
  if File.dirname(File.expand_path(__FILE__)).match %r{^/opt/t87/global}
    T87VM = true
  else
    T87VM = false
  end

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)

    if Rails.env.test?
      config.autoload_paths += %W(#{config.root}/test/lib)
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_record.schema_format = :sql

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    if T87VM
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

  def self.git_revision
    if ! Object.const_defined?('GIT_REVISION')
      return `git rev-parse HEAD`[0..7]
    else
      # At deploy time, a file gets created in config/initializers
      # with this constant defined
      return GIT_REVISION
    end
  end
end

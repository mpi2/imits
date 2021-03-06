require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module TarMits
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/reports #{config.root}/presenters)

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

    config.paths['intermediate_report_log'] = 'log/intermediate_report.log'
    config.paths['upload_path'] = File.join(Rails.root, 'uploads')

    if File.expand_path(__FILE__).match %r{^/opt/t87/global}
      require('/opt/t87/global/lib/config_rails_app'); VM.config_rails_app(config)
    end

    config.show_search_page = false

    #config.maintenance_mode.if = Proc.new { |env| File.file?(Rails.root.join("/tmp/imits-maintenance.on")) }

    #config.maintenance_mode.response = Proc.new { |env| [503, {'Content-Type' => 'text/html'}, [Rails.root.join("public/maintenance.html").read]] }

    # config.htgt_root = "https://www.sanger.ac.uk/htgt/htgt2"
    config.htgt_root = "https://stemcell.sanger.ac.uk/htgt/"
    # config.wge_root = "https://www.sanger.ac.uk/htgt/wge"
    config.wge_root = "https://wge.stemcell.sanger.ac.uk/"
    # config.lims2_root = "https://www.sanger.ac.uk/htgt/lims2"
    config.lims2_root = "https://lims2.stemcell.sanger.ac.uk/"
    config.mousemine_root = "http://www.mousemine.org/mousemine"
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

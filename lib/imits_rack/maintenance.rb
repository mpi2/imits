require 'rack'

# based on https://github.com/tilsammans/rack-maintenance
# we added a trigger file option
# that is, a file such as /tmp/imits-maintenance.on which when it exists puts the app in to maintenance mode

class ImitsRack::Maintenance

  attr_reader :app, :options

  def initialize(app, options={})
    @app     = app
    @options = options

    raise(ArgumentError, 'Must specify a :file') unless options[:file]
  end

  def call(env)
    if maintenance? && path_in_app(env)
      data = File.read(file)
      [ 503, { 'Content-Type' => content_type, 'Content-Length' => data.length.to_s }, [data] ]
    else
      app.call(env)
    end
  end

  private ######################################################################

  def content_type
    file.to_s.end_with?('json') ? 'application/json' : 'text/html'
  end

  def environment
    options[:env]
  end

  def file
    options[:file]
  end

  def trigger_file
    options[:trigger_file]
  end

  def maintenance?
    environment ? ENV[environment] : File.exists?(trigger_file)
  end

  def path_in_app(env)
    env["PATH_INFO"] !~ /^\/assets/
  end

end

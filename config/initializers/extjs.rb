module Extjs
  CONFIG = YAML.load( ERB.new(File.read(Rails.root + 'config/extjs.yml')).result(binding) )
  CONFIG['local_base_path'] = '/extjs'
  CONFIG['cdn_base_path'] = CONFIG['cdn_host'] + CONFIG['version']

  def self.base_path
    if development?
      return CONFIG['local_base_path']
    else
      return CONFIG['cdn_base_path']
    end
  end

  def self.css
    return CONFIG['css'].map {|path| base_path + '/' + path}
  end

  def self.main_js
    if development?
      return CONFIG['local_base_path'] + '/' + 'ext-all-debug.js'
    else
      return CONFIG['cdn_base_path'] + '/' + 'ext-all.js'
    end
  end

  def self.ux_js
    Dir.chdir(Rails.root + 'public/javascripts') do
      ext_ux_classes = Set.new

      Dir['**/*.js'].each do |jsfile|
        next unless File.file?(jsfile)
        matches = File.read(jsfile).scan(/('|")(Ext\.ux\.[A-Za-z0-9\._]+)('|")/).map {|i| i[1]}
        ext_ux_classes.merge(matches)
      end

      return ext_ux_classes.map {|class_name| base_path + '/examples/' + class_name.gsub(/^Ext\./, '').gsub('.', '/') + '.js'}
    end
  end

  def self.development?
    return ['development', 'test'].include? Rails.env
  end

end

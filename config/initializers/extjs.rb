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

  def self.find_all_classes
    Dir.chdir(Rails.root + 'public/javascripts') do
      classes = Set.new

      Dir['**/*.js'].each do |jsfile|
        next unless File.file?(jsfile)
        matches = File.read(jsfile).scan(/('|")((Ext\.ux|Imits)\.[A-Za-z0-9\._]+)('|")/).map {|i| i[1]}
        classes.merge(matches)
      end

      return classes.map do |class_name|
        if class_name.match /^Imits/
          '/javascripts/' + class_name.gsub('.', '/') + '.js'
        else
          CONFIG['local_base_path'] + '/examples/' + class_name.gsub(/^Ext\./, '').gsub('.', '/') + '.js'
        end
      end
    end
  end

  def self.development?
    return ['development', 'test'].include? Rails.env
  end

end

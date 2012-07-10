module Extjs
  CONFIG = YAML.load_file(Rails.root + 'config/extjs.yml')
  LOCAL_BASE_PATH = '/extjs'
  CDN_BASE_PATH = CONFIG['cdn_host'] + CONFIG['version']

  def self.base_path
    if development?
      return LOCAL_BASE_PATH
    else
      return CDN_BASE_PATH
    end
  end

  def self.css
    return CONFIG['css'].map {|path| base_path + '/' + path}
  end

  def self.main_js
    if development?
      return LOCAL_BASE_PATH + '/' + 'ext-all-debug.js'
    else
      return CDN_BASE_PATH + '/' + 'ext-all.js'
    end
  end

  def self.development?
    return ['development', 'test'].include? Rails.env
  end

end

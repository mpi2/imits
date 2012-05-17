lambda {
  processed = ERB.new(File.read(Rails.root + 'config/extjs.yaml')).result(binding)
  EXTJS_CONFIG = YAML.load(processed)
  EXTJS_CONFIG['css'].map! {|i| EXTJS_CONFIG['base_path'] + '/' + i }
  EXTJS_CONFIG['javascript'].map! {|i| EXTJS_CONFIG['base_path'] + '/' + i }
}.call

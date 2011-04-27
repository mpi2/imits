class Old::ModelBase < ActiveRecord::Base
  self.abstract_class = true

  def readonly?
    return true
  end

  def self.connect_in_environment(environment_name)
    unless File.file?(Rails.root + 'config/old_database.yml')
      raise 'Please create file config/old_database.yml with connection details for old Oracle models'
    end
    @@old_connection_settings ||= YAML::load_file Rails.root + 'config/old_database.yml'
    self.establish_connection @@old_connection_settings[environment_name]
  end
end

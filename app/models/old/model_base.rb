class Old::ModelBase < ActiveRecord::Base
  self.abstract_class = true

  def readonly?
    return true
  end

  def self.connect_in_environment(environment_name)
    @@old_connection_settings ||= YAML::load_file Rails.root + 'config/old_database.yml'
    self.establish_connection @@old_connection_settings[environment_name]
  end
end

if File.file?(Rails.root + 'config/old_database.yml')
  Old::ModelBase.connect_in_environment Rails.env
end

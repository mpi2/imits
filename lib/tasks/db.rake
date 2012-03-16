namespace :db do
  if Rails.env.development?
    ['migrate', 'rollback', 'migrate:up', 'migrate:down'].each do |taskname|
      task(taskname) do
        Rake::Task['db:schema:dump'].invoke
      end
    end
  end

  if Rails.env.development? and ENV['NO_ANNOTATE'].blank?
    task :migrate do
      Rake::Task['annotate:models'].invoke
    end
  end

  ['production', 'staging'].each do |envname|
    desc "Dump #{envname} DB into db/dump.#{envname}.sql"
    task "#{envname}:dump" do
      config = YAML.load_file("#{Rails.root}/config/database.yml")[envname]
      if ! config
        config = YAML.load_file("#{Rails.root}/config/database.#{envname}.yml")[envname]
      end
      raise "Cannot find #{envname} database config" unless config
      if config['port'].blank?; config['port'] = '5432'; end
      system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --clean --no-privileges #{config['database']} > tmp/dump.#{envname}.sql") or raise("Failed to dump #{envname} DB")
    end

    desc "Load dump of #{envname} DB (produced with db:#{envname}:dump) into current envrionment DB"
    task "#{envname}:load" do
      raise "Production environment detected" if Rails.env.production?
      raise "Cannot load into same environment" if envname == Rails.env
      config = YAML.load_file("#{Rails.root}/config/database.yml")[Rails.env]
      if config['port'].blank?; config['port'] = '5432'; end
      system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' psql -U #{config['username']} -h #{config['host']} -p #{config['port']} #{config['database']} < tmp/dump.#{envname}.sql > /dev/null") or raise("Failed to load #{envname} dump of DB")
    end

    desc "Dump #{envname} DB into current environment DB"
    task "#{envname}:clone" => ["db:#{envname}:dump", "db:#{envname}:load"]
  end

  desc 'Reset user passwords to "password"'
  task 'passwords:reset' => :environment do
    raise "Production environment detected" if Rails.env.production?

    User.all.each do |user|
      user.update_attributes!(:password => 'password')
    end
  end

  desc 'Flush caches'
  task 'flush_caches' => :environment do
    ReportCache.destroy_all
  end
end

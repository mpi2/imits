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
      tmppath = Rails.application.config.paths['tmp'].first
      config = YAML.load_file("#{Rails.root}/config/database.yml")[envname]
      if ! config
        [
         "#{Rails.root}/config/database.#{envname}.yml",
         "/opt/t87/global/conf/imits/#{envname}/database.yml"
        ].each do |config_location|
          if File.file? config_location
            config = YAML.load_file(config_location)[envname]
            break
          end
        end
      end
      raise "Cannot find #{envname} database config" unless config
      if config['port'].blank?; config['port'] = '5432'; end
      system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} -T targ_rep_genbank_files -T audits --no-privileges #{config['database']} > #{tmppath}/dump.#{envname}.sql") or raise("Failed to dump #{envname} DB")
      system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --schema-only -t targ_rep_genbank_files -t audits --no-privileges #{config['database']} >> #{tmppath}/dump.#{envname}.sql") or raise("Failed to dump #{envname} DB")
    end

    desc "Load dump of #{envname} DB (produced with db:#{envname}:dump) into current envrionment DB"
    task "#{envname}:load" do
      raise "Production environment detected" if Rails.env.production?
      tmppath = Rails.application.config.paths['tmp'].first
      config = YAML.load_file(Rails.application.config.paths['config/database'].first)[Rails.env]
      if config['port'].blank?; config['port'] = '5432'; end
      psql_cmd = "PGPASSWORD='#{config['password']}' psql -U #{config['username']} -h #{config['host']} -p #{config['port']} #{config['database']}"

      system("cd #{Rails.root}; echo 'drop schema public cascade; create schema public' | #{psql_cmd}") or raise("Failed to drop public schema in environment #{envname}")
      system("cd #{Rails.root}; #{psql_cmd} < #{tmppath}/dump.#{envname}.sql > /dev/null") or raise("Failed to load #{envname} dump of DB")
    end

    desc "Dump #{envname} DB into current environment DB"
    task "#{envname}:clone" => ["db:#{envname}:dump", "db:#{envname}:load"]

  end

  desc "Dump public DB into public/uploads/public_dump.sql"
  task :public_dump do
    uploadir = Rails.application.config.paths['upload_path'].first
    envname  = Rails.env.to_s

    config = YAML.load_file("#{Rails.root}/config/database.yml")[envname]
    if ! config
      [
       "#{Rails.root}/config/database.#{envname}.yml",
       "/opt/t87/global/conf/imits/#{envname}/database.yml"
      ].each do |config_location|
        if File.file? config_location
          config = YAML.load_file(config_location)[envname]
          break
        end
      end
    end

    `mkdir -p #{uploadir}` if Rails.env.development?
    puts uploadir

    raise "Cannot find #{envname} database config" unless config
    if config['port'].blank?; config['port'] = '5432'; end
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --column-inserts -T email_templates -T contacts -T notifications -T targ_rep_genbank_files -T audits --no-privileges #{config['database']} > #{uploadir}/public_dump.sql") or raise("Failed to public dump #{envname} DB")
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --column-inserts --schema-only -t email_templates -t contacts -t notifications -t targ_rep_genbank_files -t audits --no-privileges #{config['database']} >> #{uploadir}/public_dump.sql") or raise("Failed to public dump #{envname} DB")
    system("cd #{uploadir}; tar -cvzf 'public_dump.sql.tar.gz' public_dump.sql") or raise("Failed to compress #{uploadir}/public_dump.sql")
    system("rm #{uploadir}/public_dump.sql") or raise("Failed to clean up #{uploadir}/public_dump.sql")
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

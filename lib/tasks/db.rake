namespace :db do
  # Generate schema.rb alongside development_structure.sql, so that
  # editors/helpers/plugins that rely db/schema.rb can still use it,
  # even though the app uses the :sql schema_format for setting up the
  # test DB
  task 'structure:dump' => ['db:schema:dump']

  if Rails.env.development?
    task :migrate do
      Rake::Task['annotate:models'].invoke
    end

    namespace :migrate do
      [:up, :down, :reset, :redo].each do |t|
        task t do
          Rake::Task['annotate:models'].invoke
        end
      end
    end
  end

  desc 'Dump production DB into db/dump.production.sql'
  task 'production:dump' do
    config = YAML.load_file("#{Rails.root}/config/database.yml")['production']
    if config['port'].blank?; config['port'] = '5432'; end
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --clean --no-privileges #{config['database']} > db/dump.production.sql") or raise("Failed to dump production DB")
  end

  desc 'Load dump of production DB (produced with db:production:dump) into current envrionment DB'
  task 'production:load' do
    raise "Production environment detected" if Rails.env.production?
    config = YAML.load_file("#{Rails.root}/config/database.yml")[Rails.env]
    if config['port'].blank?; config['port'] = '5432'; end
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' psql -U #{config['username']} -h #{config['host']} -p #{config['port']} #{config['database']} < db/dump.production.sql") or raise("Failed to dump production DB")
  end

  desc 'Dump production DB into current environment DB'
  task 'production:clone' => ['db:production:dump', 'db:production:load']

  desc 'Reset user passwords to "password"'
  task 'passwords:reset' => :environment do
    raise "Production environment detected" if Rails.env.production?

    User.all.each do |user|
      user.update_attributes!(:password => 'password')
    end
  end
end

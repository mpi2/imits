namespace :db do
  ['migrate', 'rollback', 'migrate:up', 'migrate:down'].each do |taskname|
    task(taskname) do
      Rake::Task['db:schema:dump'].invoke
    end
  end

  if Rails.env.development? and ENV['NO_ANNOTATE'].blank?
    task :migrate do
      Rake::Task['annotate:models'].invoke
    end
  end

  desc 'Dump production DB into db/dump.production.sql'
  task 'production:dump' do
    config = YAML.load_file("#{Rails.root}/config/database.yml")['production']
    if ! config
      config = YAML.load_file("#{Rails.root}/config/database.production.yml")['production']
    end
    raise 'Cannot find production database config' unless config
    if config['port'].blank?; config['port'] = '5432'; end
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' pg_dump -U #{config['username']} -h #{config['host']} -p #{config['port']} --clean --no-privileges #{config['database']} > tmp/dump.production.sql") or raise("Failed to dump production DB")
  end

  desc 'Load dump of production DB (produced with db:production:dump) into current envrionment DB'
  task 'production:load' do
    raise "Production environment detected" if Rails.env.production?
    config = YAML.load_file("#{Rails.root}/config/database.yml")[Rails.env]
    if config['port'].blank?; config['port'] = '5432'; end
    system("cd #{Rails.root}; PGPASSWORD='#{config['password']}' psql -U #{config['username']} -h #{config['host']} -p #{config['port']} #{config['database']} < tmp/dump.production.sql > /dev/null") or raise("Failed to load production dump of DB")
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

namespace :db do
  namespace :test do

    namespace :fixtures do
      desc 'Load fixtures into test environment'
      task :load => :environment do
        require 'active_record/fixtures'

        ActiveRecord::Base.establish_connection('test')
        fixtures_dir = File.join(Rails.root, 'test', 'fixtures')

        Dir["#{fixtures_dir}/**/*.{yml,csv}"].each do |fixture_file|
          Fixtures.create_fixtures(fixtures_dir, fixture_file[(fixtures_dir.size + 1)..-5])
        end
      end
    end

    task :prepare do
      Rake::Task['db:test:fixtures:load'].invoke
    end

  end
end

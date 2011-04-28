namespace :db do
  desc 'Load some sample data into the DB for testing'
  task :sample_data => ['db:seed', :environment] do
    SampleData.load
  end
end

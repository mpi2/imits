unless Rails.env.development?
  namespace :db do
    namespace :structure do
      task :dump => :environment do
        puts "Skip dumping database in production..."
      end
    end
  end
end
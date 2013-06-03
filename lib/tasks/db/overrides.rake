unless Rails.env.development? || Rails.env.test?
  Rake::TaskManager.class_eval do
    def remove_task(task_name)
      @tasks.delete(task_name.to_s)
    end
  end

  Rake.application.remove_task("db:structure:dump") 

  namespace :db do
    namespace :structure do
      task :dump => :environment do
        puts "Skip dumping database in production..."
      end
    end
  end
end
Rake::Task["db:structure:dump"].clear

namespace :db do
  namespace :structure do
    task :dump do
      "This is unnecessary"
    end
  end
end
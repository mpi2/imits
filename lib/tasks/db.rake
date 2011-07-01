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

end

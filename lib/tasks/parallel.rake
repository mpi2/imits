namespace :parallel do
  task('fixtures:load', [:count] => 'db:abort_if_pending_migrations') do |t, args|
    run_in_parallel('rake db:fixtures:load RAILS_ENV=test', :count => args[:count])
  end

  task(:prepare, [:count]) do |t, args|
    Rake::Task['parallel:fixtures:load'].invoke(args[:count])
    Rake::Task['imits:generate_email_templates RAILS_ENV=test'].invoke
  end
end

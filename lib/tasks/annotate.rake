namespace :annotate do
  desc "Add/update models with new annotation"
  task :models do
    system("cd #{Rails.root}; bundle exec annotate -e tests,fixtures -i --position after")
  end
end

desc "Add/update models with new annotation"
task :annotate => ['annotate:models']

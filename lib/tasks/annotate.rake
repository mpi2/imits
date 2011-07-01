namespace :annotate do

  # Courtesy of http://sed.sourceforge.net/sed1line.txt
  SED_DELETE_TRAILING_BLANK_LINES = '-e :a -e \'/^\n*$/{$d;N;ba\' -e \'}\''

  desc "Remove all annotation and clean up stray whitespace left by annoying annotate gem"
  task :remove do
    system("cd #{Rails.root}; bundle exec annotate -d")
    system('cd '+Rails.root.to_s+'; sed -i '+SED_DELETE_TRAILING_BLANK_LINES+' `find app/models -name "*.rb"`')
  end

  desc "Add/update models with new annotation"
  task :models => [:remove] do
    system("cd #{Rails.root}; bundle exec annotate -e tests,fixtures -m -i")
    system('cd '+Rails.root.to_s+'; sed -i '+SED_DELETE_TRAILING_BLANK_LINES+' `find test/fixtures -name "*.yml"`')
  end
end

desc "Add/update models with new annotation"
task :annotate => ['annotate:models']

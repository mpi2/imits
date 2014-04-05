
namespace :solr_ck do

  DATABASE = YAML.load_file("#{Rails.root}/config/database.yml")
  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Build the ck core'
  task 'build' => [:environment] do
    #BuildCk.new.run
  end

  desc "Download the ck index as csv - place in #{Rails.env}-ck-solr.csv"
  task 'get_csv' => [:environment] do
    home = Dir.home
    command = "curl -o #{home}/Desktop/#{Rails.env}-ck-solr.csv '#{SOLR_UPDATE[Rails.env]['index_proxy']['ck']}/select/?q=*:*&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command
    output = `#{command}`
    puts output if output
  end

end


namespace :solr_bulk do

  SOLR_BULK = YAML.load_file("#{Rails.root}/config/solr_bulk.yml")

  desc 'Run the bulk loader'
  task 'index:load' => [:environment] do
    SolrBulk::Refresh.run
  end

  desc 'Compare'
  task 'test:compare' => [:environment] do
    SolrBulk::Compare.run
  end

  desc 'Compare2'
  task 'test:compare2' => [:environment] do
    SolrBulk::Compare2::CompareGenes.new.run
  end

  desc 'Load particular doc - supply type & id'
  task 'index:load_with_parameters', [:type, :id] => :environment do |t, args|
    #args.with_defaults(:targets => 'all')
    raise "#### not yet implemented!"
  end

  desc 'get postgres version'
  task 'db:version' => [:environment] do
    ActiveRecord::Base.connection.execute('select version();')
  end

  desc 'test load'
  task 'test' => [:environment] do
    #command = "PGPASSWORD=#{SOLR_BULK['connection']['password']} psql -U #{SOLR_BULK['connection']['user']} -d #{SOLR_BULK['connection']['database']} -h #{SOLR_BULK['connection']['host']} < #{Rails.root}/script/solr_bulk/solr_bulk.sql"
    #puts command.blue
    #output = `#{command}`
    #puts output if output

    puts "zeus rake solr_bulk:index:load".blue

    Rake::Task['solr_bulk:index:load'].invoke

    puts "zeus rake solr_bulk:test:compare".blue
    Rake::Task['solr_bulk:test:compare'].invoke
  end

  desc 'normalize csv'
  task 'normalize_csv', [:filename] => :environment do |t, args|
    raise "#### supply filename!" if args[:filename].nil?

    SolrBulk::Util.normalize_csv args[:filename]
  end

  #desc 'test csv all'
  #task 'test_csv_all' => [:environment] do
  #  #command = "PGPASSWORD=#{SOLR_BULK['connection']['password']} psql -U #{SOLR_BULK['connection']['user']} -d #{SOLR_BULK['connection']['database']} -h #{SOLR_BULK['connection']['host']} < #{Rails.root}/script/solr_bulk/solr_bulk.sql"
  #  #puts command.blue
  #  #output = `#{command}`
  #  #puts output if output
  #
  #  #puts 'solr_bulk:index:load'.blue
  #  #Rake::Task['solr_bulk:index:load'].invoke
  #
  #  legal_targets = %W{gene phenotype_attempt mi_attempt allele}
  #  #legal_targets = %W{allele}
  #
  #  pp legal_targets
  #
  #  legal_targets.each do |target|
  #    #puts "#### target: #{target}"
  #    Rake::Task['solr_bulk:test_csv'].invoke(target)
  #    Rake::Task['solr_bulk:test_csv'].reenable
  #  end
  #end

  desc 'test csv all'
  task 'test_csv_all' => [:environment] do
    command = "PGPASSWORD=#{SOLR_BULK['connection']['password']} psql -U #{SOLR_BULK['connection']['user']} -d #{SOLR_BULK['connection']['database']} -h #{SOLR_BULK['connection']['host']} < #{Rails.root}/script/solr_bulk/solr_bulk.sql"
    puts command.blue
    output = `#{command}`
    puts output if output

    puts 'solr_bulk:index:load'.blue
    Rake::Task['solr_bulk:index:load'].invoke

    home = Dir.home
    filename1 = "#{home}/Desktop/solr-old-all.csv"
    solr = "http://localhost:8985/solr"

    SolrBulk::Util.download_and_normalize filename1, solr

    filename2 = "#{home}/Desktop/solr-new-all.csv"
    solr = "http://localhost:8983/solr"

    SolrBulk::Util.download_and_normalize filename2, solr

    command = "sort #{filename1} > #{filename1}"
    puts command.blue
    #output = `#{command}`
    #puts output if output

    command = "sort #{filename2} > #{filename2}"
    puts command.blue
    #output = `#{command}`
    #puts output if output

    puts "diff #{filename1} #{filename2}".blue
    puts "meld #{filename1} #{filename2} &".blue
  end

  desc 'download_and_normalize'
  task 'download_and_normalize', [:filename, :solr] => :environment do |t, args|
    raise "#### supply filename!" if args[:filename].nil?
    raise "#### supply solr!" if args[:solr].nil?
    SolrBulk::Util.download_and_normalize args[:filename], args[:solr]
  end

  desc 'test csv all commands'
  task 'test_csv_all_commands' => [:environment] do
    command = "PGPASSWORD=#{SOLR_BULK['connection']['password']} psql -U #{SOLR_BULK['connection']['user']} -d #{SOLR_BULK['connection']['database']} -h #{SOLR_BULK['connection']['host']} < #{Rails.root}/script/solr_bulk/solr_bulk.sql"
    puts command.blue
    #output = `#{command}`
    #puts output if output

    puts 'zeus rake solr_bulk:index:load'.blue
    #Rake::Task['solr_bulk:index:load'].invoke

    home = Dir.home
    filename1 = "#{home}/Desktop/solr-old-all.csv"
    solr = "http://localhost:8985/solr"

    puts "rm -f #{filename1}".blue
    puts "zeus rake solr_bulk:download_and_normalize['#{filename1}','#{solr}']".blue

    #SolrBulk::Util.download_and_normalize filename1, solr

    filename2 = "#{home}/Desktop/solr-new-all.csv"
    solr = "http://localhost:8983/solr"

    #SolrBulk::Util.download_and_normalize filename2, solr

    puts "rm -f #{filename2}".blue
    puts "zeus rake solr_bulk:download_and_normalize['#{filename2}','#{solr}']".blue

    #filename.gsub(/\.csv/, '-regular.csv'), filename

    command = "sort #{filename1.gsub(/\.csv/, '-regular.csv')} > #{filename1}"
    puts command.blue
    #output = `#{command}`
    #puts output if output

    command = "sort #{filename2.gsub(/\.csv/, '-regular.csv')} > #{filename2}"
    puts command.blue
    #output = `#{command}`
    #puts output if output

    puts "diff #{filename1} #{filename2} | wc".blue
    puts "diff #{filename1} #{filename2}".blue
    puts "meld #{filename1} #{filename2} &".blue
  end

  desc 'test csv'
  task 'test_csv', [:target] => :environment do |t, args|
    raise "#### supply target!" if args[:target].nil?
    legal_targets = %W{gene phenotype_attempt mi_attempt allele}
    raise "#### unrecognised target (#{args[:target]})!" if ! legal_targets.include? args[:target]

    #command = "PGPASSWORD=#{SOLR_BULK['connection']['password']} psql -U #{SOLR_BULK['connection']['user']} -d #{SOLR_BULK['connection']['database']} -h #{SOLR_BULK['connection']['host']} < #{Rails.root}/script/solr_bulk/solr_bulk.sql"
    #puts command.blue
    #output = `#{command}`
    #puts output if output

    #puts 'solr_bulk:index:load'.blue
    #Rake::Task['solr_bulk:index:load'].invoke

    target = args[:target]

    home = Dir.home

    `rm -f #{home}/Desktop/solr-old-#{target}.csv`
    `rm -f #{home}/Desktop/solr-new-#{target}.csv`
    `rm -f #{home}/Desktop/solr-old-#{target}-regular.csv`
    `rm -f #{home}/Desktop/solr-new-#{target}-regular.csv`

    command = "curl -o #{home}/Desktop/solr-old-#{target}.csv 'http://localhost:8985/solr/allele/select/?q=type%3A#{target}&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command.blue
    output = `#{command}`
    puts output if output

    command = "curl -o #{home}/Desktop/solr-new-#{target}.csv 'http://localhost:8983/solr/allele/select/?q=type%3A#{target}&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
    puts command.blue
    output = `#{command}`
    puts output if output

    puts 'normalize_csv'.blue
    SolrBulk::Util.normalize_csv "#{home}/Desktop/solr-old-#{target}.csv"
    SolrBulk::Util.normalize_csv "#{home}/Desktop/solr-new-#{target}.csv"

    #command = "diff #{home}/Desktop/solr-old-#{target}-regular.csv #{home}/Desktop/solr-new-#{target}-regular.csv"
    #puts command.blue
    #output = `#{command}`
    #puts output if output

    if target == 'allele'
      command = "sort #{home}/Desktop/solr-old-#{target}-regular.csv > #{home}/Desktop/solr-old-#{target}-regular2.csv"
      puts command.blue
      output = `#{command}`
      puts output if output

      command = "sort #{home}/Desktop/solr-new-#{target}-regular.csv > #{home}/Desktop/solr-new-#{target}-regular2.csv"
      puts command.blue
      output = `#{command}`
      puts output if output

      puts "diff #{home}/Desktop/solr-old-#{target}-regular2.csv #{home}/Desktop/solr-new-#{target}-regular2.csv".green
      puts "meld #{home}/Desktop/solr-old-#{target}-regular2.csv #{home}/Desktop/solr-new-#{target}-regular2.csv &".blue
    else
      puts "diff #{home}/Desktop/solr-old-#{target}-regular.csv #{home}/Desktop/solr-new-#{target}-regular.csv".green
      puts "meld #{home}/Desktop/solr-old-#{target}-regular.csv #{home}/Desktop/solr-new-#{target}-regular.csv &".blue
    end
  end

  #desc 'test csv2'
  #task 'test_csv2', [:target] => :environment do |t, args|
  #  target = args[:target]
  #  home = Dir.home
  #
  #  #puts 'solr_bulk:index:load'.blue
  #  #Rake::Task['solr_bulk:index:load'].invoke
  #
  #  #command = "curl -o #{home}/Desktop/solr-old-#{target}.csv 'http://localhost:8985/solr/allele/select/?q=type%3A#{target}&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
  #  #puts command.blue
  #  #output = `#{command}`
  #  #puts output if output
  #  #
  #  #command = "curl -o #{home}/Desktop/solr-new-#{target}.csv 'http://localhost:8983/solr/allele/select/?q=type%3A#{target}&version=2.2&start=0&rows=100000&indent=on&wt=csv'"
  #  #puts command.blue
  #  #output = `#{command}`
  #  #puts output if output
  #
  #  puts 'normalize_csv'.blue
  #  SolrBulk::Util.normalize_csv "#{home}/Desktop/solr-old-#{target}.csv", [target]
  #  SolrBulk::Util.normalize_csv "#{home}/Desktop/solr-new-#{target}.csv", [target]
  #
  #  exit if target != 'allele'
  #
  #  command = "sort #{home}/Desktop/solr-old-#{target}-regular.csv > #{home}/Desktop/solr-old-#{target}-regular2.csv"
  #  puts command.blue
  #  output = `#{command}`
  #  puts output if output
  #
  #  command = "sort #{home}/Desktop/solr-new-#{target}-regular.csv > #{home}/Desktop/solr-new-#{target}-regular2.csv"
  #  puts command.blue
  #  output = `#{command}`
  #  puts output if output
  #end
end

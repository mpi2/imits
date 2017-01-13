require 'pp'
require 'optparse'

namespace :solr do

  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Create a tsv containing the documents for the allele2 cores'

  task 'index:generate:allele2:tsv' => [:environment] do |t, args|

    options = {}
    rake_options = {}
    # Defaults
    options[:show_eucommtoolscre] = false
    options[:file_name] = "#{Rails.root}/tmp/allele2-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tsv"
    options[:exclude_impc_data] = false

    OptionParser.new do |opts|
      opts.banner = "Usage: rake index:generate:allele2:tsv [options]"
      opts.on("-c", "--[no-]show_eucommtoolscre", "Include Cre Data") { |show_eucommtoolscre| rake_options[:show_eucommtoolscre] = show_eucommtoolscre }
      opts.on("-f", "--file_name ARG", "Specify file") { |file_name| options[:file_name] = file_name }
      opts.on("-x", "--[no-]exclude_impc_data", "Exclude IMPC data") { |exclude_impc_data| rake_options[:exclude_impc_data] = exclude_impc_data }
      opts.on("-g", "--marker_symbols x,y,z", Array, "Specify Gene Marker Symbols to create docs for") { |marker_symbols| options[:marker_symbols] = marker_symbols }
    end.parse!

    if rake_options[:exclude_impc_data] != true
      puts "## Start Build of IMPC Allele 2 Core #{Time.now}"
      SolrData::Allele2CoreData.new(options).run
      puts "## Completed Build of IMPC Allele 2 Core#{Time.now}"
    end

    if rake_options[:show_eucommtoolscre]
      puts "## Start Build of Cre Allele 2 Core #{Time.now}"
      SolrData::Allele2CoreData.new(options.merge({:show_eucommtoolscre => true})).run
      puts "## Completed Build of Cre Allele 2 Core#{Time.now}"
    end
  end

  desc 'Create a tsv containing the documents for the product cores'
  task 'index:generate:product:tsv' => [:environment] do |t, args|

    options = {}
    rake_options = {}
    options[:show_eucommtoolscre] = false
    options[:file_name] = "#{Rails.root}/tmp/product-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tsv"
    options[:exclude_impc_data] = false
    options[:process_mice] = true
    options[:process_es_cells] = true
    options[:process_targeting_vectors] = true
    options[:process_intermediate_vectors] = true

    OptionParser.new do |opts|
      opts.banner = "Usage: rake index:generate:product:tsv [options]"
      opts.on("-c", "--[no-]show_eucommtoolscre", "Include Cre Data") { |show_eucommtoolscre| rake_options[:show_eucommtoolscre] = show_eucommtoolscre  }
      opts.on("-f", "--file_name ARG", "Specify file") { |file_name| options[:file_name] = file_name }
      opts.on("-x", "--[no-]exclude_impc_data", "Exclude IMPC data") { |exclude_impc_data| rake_options[:exclude_impc_data] = exclude_impc_data }
      opts.on("-g", "--marker_symbols x,y,z", Array, "Specify Gene Marker Symbols to create docs for") { |marker_symbols| options[:marker_symbols] = marker_symbols }

      opts.on("-m", "--[no-]exclude_mice", "Exclude Mice data") { |exclude_mice| options[:process_mice] = !exclude_mice }
      opts.on("-e", "--[no-]exclude_es_cells", "Exclude ES Cell data") { |exclude_es_cells| options[:process_es_cells] = !exclude_es_cells }
      opts.on("-t", "--[no-]exclude_targeting_vectors", "Exclude Targeting Vector data") { |exclude_targeting_vectors| options[:process_targeting_vectors] = !exclude_targeting_vectors }
      opts.on("-i", "--[no-]exclude_intermediate_vectors", "Exclude Intermediate Vector data") { |exclude_intermediate_vectors| options[:process_intermediate_vectors] = !exclude_intermediate_vectors }
    end.parse!

    if rake_options[:exclude_impc_data] != true
      puts "## Start Build of IMPC Product Core #{Time.now}"
      SolrData::ProductCoreData.new(options).run
      puts "## Completed Build of IMPC Product Core#{Time.now}"
    end

    if rake_options[:show_eucommtoolscre]
      puts "## Start Build of Cre Product Core #{Time.now}"
      SolrData::ProductCoreData.new(options.merge({:show_eucommtoolscre => true})).run
      puts "## Completed Build of Cre Product Core#{Time.now}"
    end
  end

  desc 'Ping the solr'
  task 'index:ping', [:solr_core] => [:environment] do |t, args|
    raise 'Which Solr Core should be tested' if args[:solr_core].blank?
    raise 'Core is not configured in solr_update.yaml' unless SOLR_UPDATE[Rails.env]['index_proxy'].has_key?(args[:solr_core])
    command = 'curl -s SOLR_SUBS/select/?q=*:*&version=2.2&start=0&rows=1 |grep -o -E "name=\"status\">([0-9]+)<"|cut -f2 -d\>|cut -f1 -d\<'.gsub(/SOLR_SUBS/, SOLR_UPDATE[Rails.env]['index_proxy'][args[:solr_core]])
    output = `#{command}`
    if output.to_s.length > 0 && output.to_i == 0
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy'][args[:solr_core]]} up and running!"
    elsif output.empty?
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy'][args[:solr_core]]} NOT running!"
    else
      puts "#### #{SOLR_UPDATE[Rails.env]['index_proxy'][args[:solr_core]]} broken!"
    end
  end

  desc "Download the index as tsv"
  task 'index:download:tsv' , [:solr_core, :file_name] => [:environment] do |t, args|
    raise 'Which Solr Core should be tested' if args[:solr_core].blank?
    raise 'Core is not configured in solr_update.yaml' unless SOLR_UPDATE[Rails.env]['index_proxy'].has_key?(args[:solr_core])
    args.with_defaults(
        :file_name  => "#{Rails.root}/tmp/#{args[:solr_core]}"
    )
    command = "curl -o #{args[:file_name]}-#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tsv '#{SOLR_UPDATE[Rails.env]['index_proxy'][args[:solr_core]]}/select/?q=*:*&version=2.2&start=0&rows=1000000&indent=on&wt=csv&csv.escape=&csv.separator=%09'&csv.encapsulator=&csv.mv.separator=|"
    puts command
    output = `#{command}`
    puts output if output
  end

end

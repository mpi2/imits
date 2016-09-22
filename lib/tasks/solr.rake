require 'pp'

namespace :solr do

  SOLR_UPDATE = YAML.load_file("#{Rails.root}/config/solr_update.yml")

  desc 'Create a tsv containing the documents for the allele2 cores'

  task 'index:generate:allele2:tsv' , [:file_name, :eucommtools_cre, :marker_symbols] => [:environment] do |t, args|

    options = {show_eucommtoolscre: args[:eucommtools_cre] == 'true' ? true : false, file_name: "#{!args[:file_name].blank? ? args[:file_name] : "#{Rails.root}/tmp/allele2"}-#{args[:eucommtools_cre] == true ? 'eucommmtoolscre-': ''}#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tsv"}
    options[:marker_symbols] = args[:marker_symbols] unless args[:marker_symbols].blank?

    puts "## Start Rebuild of the Allele 2 Core #{Time.now}"
    SolrData::Allele2CoreData.new(options).run
    puts "## Completed Rebuild of the Allele 2 Core#{Time.now}"
  end

  desc 'Create a tsv containing the documents for the product cores'
  task 'index:generate:product:tsv', [:file_name, :eucommtools_cre, :process_mice, :process_es_cells, :process_targeting_vectors, :process_intermediate_vectors, :marker_symbols] => [:environment] do |t, args|

    options = {show_eucommtoolscre: args[:eucommtools_cre] == 'true' ? true : false, file_name: "#{!args[:file_name].blank? ? args[:file_name] : "#{Rails.root}/tmp/product"}-#{args[:eucommtools_cre] == true ? 'eucommmtoolscre-': ''}#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.tsv"}
    options[:process_mice] = false if args[:process_mice] == 'false'
    options[:process_es_cells] = false  if args[:process_es_cells] == 'false'
    options[:process_targeting_vectors] = false  if args[:process_targeting_vectors] == 'false'
    options[:process_intermediate_vectors] = false if args[:process_intermediate_vectors] == 'false'
    options[:marker_symbols] = args[:marker_symbols] unless args[:marker_symbols].blank?

    puts "## Start Rebuild of the Product Core #{Time.now}"
    SolrData::ProductCoreData.new(options).run
    puts "## Completed Rebuild of the Product Core#{Time.now}"
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

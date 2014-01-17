
require 'pp'

namespace :solr_orphans do
  LIMIT = -1
  ROWS = 50000

  @options = { :commit => false, :dump => false }

  def check_generic_imits(klass)
    target = klass.name.underscore
    target = 'allele' if klass.name == ::TargRep::TargetedAllele.name

    missing_array = []

    proxy = SolrUpdate::IndexProxy::Allele.new

    pp SolrUpdate::IndexProxy::Allele.get_uri

    solr_params = {:q => "type:#{target}", :rows => ROWS}
    docs = proxy.search solr_params

    max = klass.all.size > docs.size ? klass.all.size : docs.size
    min = klass.all.size < docs.size ? klass.all.size : docs.size

    count = 0

    klass.all.each do |item|

      if klass.name == ::TargRep::TargetedAllele.name
        next if item.es_cells.any? { |item| ! item.report_to_public }
      end

      solr_params = {:q => "type:#{target} id:#{item.id}", :rows => ROWS}
      docs2 = proxy.search solr_params
      sleep 2

      if ! docs2 || docs2.size == 0
        missing_array.push item.id
        next
      end

      # break if count > 10

      count += 1
    end

    puts "#### #{target}: (#{klass.all.size}/#{count}/#{docs.size}) #{max-min}"
    puts "#### #{target}: (#{count}/#{docs.size}) #{max-min}"
    #    puts "#### orphans: #{missing_array.size}"
  end

  def check_generic_solr(klass, target = klass.name.underscore)
    missing_array = []
    counter = 0

    proxy = SolrUpdate::IndexProxy::Allele.new

    pp SolrUpdate::IndexProxy::Allele.get_uri

    solr_params = {:q => "type:#{target}", :rows => ROWS}
    docs = proxy.search solr_params

    puts "#### found #{docs.size} #{target} docs!"

    docs.each do |doc|
      item = klass.find_by_id doc["id"].to_i

      missing_array.push doc["id"] if ! item

      pp doc if @options[:dump] && ! item

      counter += 1 if ! item
      break if LIMIT > 0 && counter >= LIMIT
    end

    puts "#### orphans: #{missing_array.size}"
  end

  desc 'List the counts for orphans (imits)'
  task :imits, [:mode] => :environment do |t, args|
    args.with_defaults(:mode => 'none')

    @options[:dump] = args[:mode] == 'dump'

    puts "#### use bundle exec rake solr_bytemark:orphans_inverse['dump'] to list id's" if ! @options[:dump]

    check_generic_imits(::TargRep::TargetedAllele)
    #check_generic_imits(::MiAttempt)
    #check_generic_imits(::Gene)
    #check_generic_imits(::PhenotypeAttempt)
  end

  desc 'List the counts for orphan docs'
  task :bytemark, [:mode] => :environment do |t, args|
    args.with_defaults(:mode => 'none')

    @options[:dump] = args[:mode] == 'dump'

    puts "#### use bundle exec rake solr_bytemark:orphans['dump'] to list id's" if ! @options[:dump]

    check_generic_solr(::TargRep::TargetedAllele, 'allele')
    check_generic_solr(::MiAttempt)
    check_generic_solr(::Gene)
    check_generic_solr(::PhenotypeAttempt)
  end

end

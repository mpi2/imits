
require 'pp'

namespace :solr_bytemark do
  LIMIT = -1
  ROWS = 50000

  @options = { :commit => false, :dump => false }

  #hash = {
  #  'allele' => ::TargRep::TargetedAllele,
  #  MiAttempt.name.underscore.to_s => MiAttempt,
  #  Gene.name.underscore.to_s => Gene,
  #  PhenotypeAttempt.name.underscore.to_s => PhenotypeAttempt
  #}

  #  def check_generic_inverse(klass)
  #
  #    target = klass.name.underscore
  #    target = 'allele' if klass.name == ::TargRep::TargetedAllele.name
  #
  #    missing_array = []
  #
  #    proxy = SolrUpdate::IndexProxy::Allele.new
  #
  #    pp SolrUpdate::IndexProxy::Allele.get_uri
  #
  #    solr_params = {:q => "type:#{target}", :rows => ROWS}
  #    docs = proxy.search solr_params
  #
  #    max = klass.all.size > docs.size ? klass.all.size : docs.size
  #    min = klass.all.size < docs.size ? klass.all.size : docs.size
  #
  #    count = 0
  #
  #    klass.all.each do |item|
  #
  #      if klass.name == ::TargRep::TargetedAllele.name
  #        #next  && (!item.es_cells || !item.es_cells.report_to_public)
  #        #item.es_cells.each do |thing|
  #        #end
  #        next if item.es_cells.any? { |thing| ! thing.report_to_public }
  #      end
  #
  #      solr_params = {:q => "type:#{target} id:#{item.id}", :rows => ROWS}
  #      docs2 = proxy.search solr_params
  #
  #      if ! docs2 || docs2.size == 0
  #        missing_array.push item.id
  #        #pp item
  #        #break
  #        next
  #      end
  #
  #     # break if count > 10
  #
  #      count += 1
  #    end
  #
  #    puts "#### #{target}: (#{klass.all.size}/#{count}/#{docs.size}) #{max-min}"
  #    puts "#### #{target}: (#{count}/#{docs.size}) #{max-min}"
  ##    puts "#### orphans: #{missing_array.size}"
  #  end

  def check_generic(klass, target = klass.name.underscore)
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

  def delete_generic(klass, target = klass.name.underscore)
    missing_array = []
    counter = 0

    proxy = SolrUpdate::IndexProxy::Allele.new

    pp SolrUpdate::IndexProxy::Allele.get_uri

    solr_params = {:q => "type:#{target}", :rows => ROWS}
    docs = proxy.search solr_params

    puts "#### found #{docs.size} #{target} docs!"

    docs.each do |doc|
      item = klass.find_by_id doc["id"].to_i

      if ! item
        missing_array.push doc["id"]
        reference = {'type' => target, 'id' => doc["id"]}
        SolrUpdate::Queue.enqueue_for_delete(reference) if @options[:commit]
      end

      counter += 1 if ! item
      break if LIMIT > 0 && counter >= LIMIT
    end

    puts "#### orphans: #{missing_array.size}"

    return counter
  end

  #desc 'List the counts for orphan docs (inverse)'
  #task :orphans_inverse, [:mode] => :environment do |t, args|
  #  args.with_defaults(:mode => 'none')
  #
  #  @options[:dump] = args[:mode] == 'dump'
  #
  #  puts "#### use bundle exec rake solr_bytemark:orphans_inverse['dump'] to list id's" if ! @options[:dump]
  #
  #  check_generic_inverse(::TargRep::TargetedAllele)
  #  #check_generic_inverse(::MiAttempt)
  #  #check_generic_inverse(::Gene)
  #  #check_generic_inverse(::PhenotypeAttempt)
  #end

  desc 'List the counts for orphan docs'
  task :orphans, [:mode] => :environment do |t, args|
    args.with_defaults(:mode => 'none')

    @options[:dump] = args[:mode] == 'dump'

    puts "#### use bundle exec rake solr_bytemark:orphans['dump'] to list id's" if ! @options[:dump]

    check_generic(::TargRep::TargetedAllele, 'allele')
    check_generic(::MiAttempt)
    check_generic(::Gene)
    check_generic(::PhenotypeAttempt)
  end

  desc 'Delete orphan docs'
  task :orphans_delete, [:mode] => :environment do |t, args|
    args.with_defaults(:mode => 'none')

    @options[:commit] = args[:mode] == 'commit'

    puts "#### use bundle exec rake solr_bytemark:orphans_delete['commit'] to enable doc removal" if ! @options[:commit]

    counter = delete_generic(::TargRep::TargetedAllele, 'allele')
    #counter += delete_generic(::MiAttempt)
    #counter += delete_generic(::Gene)
    #counter += delete_generic(::PhenotypeAttempt)

    SolrUpdate::Queue.run(:limit => counter) if @options[:commit]
  end

  # RAILS_ENV=staging bundle exec rake solr_bytemark:orphan_delete['commit',5577,'allele']
  # no spaces

  desc 'Delete single orphan doc'
  task :orphan_delete, [:mode, :id, :type] => :environment do |t, args|
    args.with_defaults(:mode => 'none')

    @options[:commit] = args[:mode] == 'commit'

    puts "#### use bundle exec rake solr_bytemark:orphan_delete['commit',5577,'allele'] to enable doc removal" if ! @options[:commit]

    puts "#### supply id!" if ! args[:id]
    puts "#### supply type!" if ! args[:type]

    next if ! args[:id] || ! args[:type]

    if args[:id] && args[:type]
      reference = {'type' => args[:type], 'id' => args[:id]}
      puts "#### reference: #{reference}"
      SolrUpdate::Queue.enqueue_for_delete(reference) if @options[:commit]
      SolrUpdate::Queue.run if @options[:commit]
    end
  end

  desc 'Show orphan doc'
  task :orphan_show, [:id, :type] => :environment do |t, args|

    puts "#### supply id!" if ! args[:id]
    puts "#### supply type!" if ! args[:type]

    next if ! args[:id] || ! args[:type]

    proxy = SolrUpdate::IndexProxy::Allele.new
    solr_params = {:q => "id:#{args[:id]} type:#{args[:type]}", :rows => ROWS}
    docs = proxy.search solr_params

    if args[:type] == 'allele'
      allele = TargRep::TargetedAllele.find_by_id args[:id]
      puts "#### allele:" if allele
      pp allele if allele
      puts "#### ORPHAN!" if ! allele
    end

    docs.each { |doc| pp doc }
  end

  #desc 'Submit alleles'
  #task :submit, [:mode] => :environment do |t, args|
  #  args.with_defaults(:mode => 'none')
  #
  #  @options[:commit] = args[:mode] == 'commit'
  #
  #  puts "#### use bundle exec rake solr_bytemark:submit['commit'] to run queue" if ! @options[:commit]
  #
  #  enqueuer = SolrUpdate::Enqueuer.new
  #
  #  hash = {}
  #  TargRep::TargetedAllele.all.each do |allele|
  #    next if allele.es_cells.any? { |thing| ! thing.report_to_public }
  #    hash[allele.id] = 1
  #    enqueuer.allele_updated(allele) if @options[:commit]
  #  end
  #
  #  SolrUpdate::Queue.run(:limit => hash.keys.size) if @options[:commit]
  #
  #  puts "#### Found #{hash.keys.size} / #{TargRep::TargetedAllele.count} alleles"
  #end

end

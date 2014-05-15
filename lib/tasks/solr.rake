
require 'pp'

namespace :solr do
  desc 'Run the SOLR update queue to send recent changes to the index'
  task 'update' => [:environment] do
    SolrUpdate::Queue.run
  end

  task 'update_part' => [:environment] do
    SolrUpdate::Queue.run(:limit => 500)
  end

  task 'update_all' => [:environment] do
    SolrUpdate::Queue.run(:limit => nil)
  end

  desc 'How many queue items are there in the queue?'
  task 'update:count' => [:environment] do
    puts SolrUpdate::Queue::Item.count
  end

  desc 'Enqueue every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt for solr update'
  task 'update:enqueue:all' => [:environment] do
    ApplicationModel.transaction do

      puts "#### enqueueing mi_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }

      puts "#### enqueueing alleles..."
      enqueuer = SolrUpdate::Enqueuer.new
      TargRep::TargetedAllele.all.each { |a| enqueuer.allele_updated(a) }

      if Rails.configuration.enable_solr_phenotype_attempt
        puts "#### enqueueing phenotype_attempts..."
        enqueuer = SolrUpdate::Enqueuer.new
        PhenotypeAttempt.all.each { |p| enqueuer.phenotype_attempt_updated(p) }
      end

      puts "#### enqueueing genes..."
      enqueuer = SolrUpdate::Enqueuer.new
      Gene.all.each { |g| enqueuer.gene_updated(g) }
    end
  end

  task 'update:run_queue:all' => [:environment] do
    SolrUpdate::Queue.run(:limit => nil)
  end

  desc 'Show solr details'
  task 'which' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
  end

  desc 'Sync every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt with the SOLR index'
  task 'update:all' => ['which', 'update:enqueue:all', 'update:run_queue:all']

  task 'update:mi_attempts' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri

    ApplicationModel.transaction do
      puts "#### enqueueing mi_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      counter = 0
      MiAttempt.all.each do |i|
        enqueuer.mi_attempt_updated(i)
        counter += 1
        #break if counter > 10
      end

      puts "#### running mi_attempts (#{counter})..."
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:mi_attemptsp' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do
      puts "#### enqueueing mi_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      counter = 0
      MiAttempt.all.each do |i|
        next if ! i.phenotype_attempts || i.phenotype_attempts.size == 0
        enqueuer.mi_attempt_updated(i)
        counter += 1
      end

      puts "#### running mi_attempts (#{counter})..."
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:alleles' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do
      puts "#### enqueueing alleles..."
      enqueuer = SolrUpdate::Enqueuer.new

      counter = 0
      TargRep::TargetedAllele.all.each do |a|
        enqueuer.allele_updated(a)
        counter += 1
        #break if counter > 10
      end

      puts "#### running alleles (#{counter})..."
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:phenotype_attempts' => [:environment] do
    next if ! Rails.configuration.enable_solr_phenotype_attempt

    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do

      puts "#### enqueueing phenotype_attempts..."

      enqueuer = SolrUpdate::Enqueuer.new
      counter = 0
      PhenotypeAttempt.all.each do |p|
        enqueuer.phenotype_attempt_updated(p)
        counter += 1
        #break if counter > 10
      end

      puts "#### running phenotype_attempts (#{counter})..."

      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:gene_single', [:marker_symbol] => :environment do |t, args|
    pp SolrUpdate::IndexProxy::Allele.get_uri
    args.with_defaults(:marker_symbol => nil)

    raise "#### provide marker symbol!" if ! args[:marker_symbol]

    ApplicationModel.transaction do
      gene = Gene.find_by_marker_symbol args[:marker_symbol]

      raise "#### cannot find marker symbol '#{args[:marker_symbol]}'" if ! gene

      enqueuer = SolrUpdate::Enqueuer.new
      enqueuer.gene_updated(gene)

      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:genes' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do
      puts "#### enqueueing genes..."
      enqueuer = SolrUpdate::Enqueuer.new
      counter = 0
      Gene.all.each do |g|
        enqueuer.gene_updated(g)
        counter += 1
        #break if counter > 1000
        #break if g.marker_type.to_s.length > 0
      end

      puts "#### running genes... (#{counter})"
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  #  task "update:gene_single", [:marker_symbol] do |task, args|
  #  task :orphans, [:mode] => :environment do |t, args|
  #  task 'update:gene_single' => [:environment] do

  #task 'update:gene_single', [:marker_symbol] => :environment do |t, args|
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #  args.with_defaults(:marker_symbol => nil)
  #
  #  raise "#### provide marker symbol!" if ! args[:marker_symbol]
  #
  #  gene = Gene.find_by_marker_symbol args[:marker_symbol]
  #
  #  raise "#### cannot find marker symbol '#{args[:marker_symbol]}'" if ! gene
  #
  #  #    pp gene
  #
  #  ApplicationModel.transaction do
  #    puts "#### enqueueing gene..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    enqueuer.gene_updated(gene)
  #
  #    puts "#### enqueueing alleles..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    counter = 0
  #    gene.allele.each do |i|
  #      enqueuer.allele_updated(i)
  #      counter += 1
  #    end
  #    puts "#### running alleles (#{counter})..."
  #    SolrUpdate::Queue.run(:limit => nil)
  #
  #    puts "#### enqueueing mi_attempts..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    counter = 0
  #    gene.mi_attempts.each do |i|
  #      enqueuer.mi_attempt_updated(i)
  #      counter += 1
  #    end
  #    puts "#### running mi_attempts (#{counter})..."
  #    SolrUpdate::Queue.run(:limit => nil)
  #
  #    puts "#### enqueueing phenotype_attempts..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    counter = 0
  #    gene.phenotype_attempts.each do |i|
  #      enqueuer.phenotype_attempt_updated(i)
  #      counter += 1
  #    end
  #    puts "#### running phenotype_attempts (#{counter})..."
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

  desc 'Sync phenotype_attempts, mi_attempts'
  task 'update:mi_pa' => ['update:phenotype_attempts', 'update:mi_attempts']

  #task 'check:genes' => [:environment] do
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #
  #  Gene.all.each do |g|
  #    SolrUpdate::DocFactory.add_project_details(g)
  #  end
  #end
  #
  #task 'update:projects' => [:environment] do
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #
  #  ApplicationModel.transaction do
  #    counter = 0
  #
  #    TargRep::IkmcProject.find_each(:batch_size => 500) do |object|
  #
  #      object.targeting_vectors.each do |vector|
  #        enqueuer.gene_updated(vector.allele.gene)
  #        counter += 1
  #      end
  #
  #      object.es_cells.each do |es_cell|
  #        enqueuer.gene_updated(es_cell.allele.gene)
  #        counter += 1
  #      end
  #    end
  #
  #    puts "#### running projects... (#{counter})"
  #
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

  #task 'update:allele_single' => [:environment] do
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #  ApplicationModel.transaction do
  #    puts "#### enqueueing allele..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #
  #    TargRep::TargetedAllele.all.each do |a|
  #      if a.gene.marker_symbol == 'Zrsr2'
  #        enqueuer.allele_updated(a)
  #      end
  #    end
  #
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

  #task 'update:allele_single' => [:environment] do
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #  ApplicationModel.transaction do
  #    puts "#### enqueueing allele..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #
  #    #TargRep::TargetedAllele.all.each do |a|
  #    #  if a.gene.marker_symbol == 'Zrsr2'
  #    #    enqueuer.allele_updated(a)
  #    #  end
  #    #end
  #
  #    gene = Gene.find_by_marker_symbol 'Zrsr2'
  #
  #    if gene
  #      gene.allele.each do |a|
  #        enqueuer.allele_updated(a)
  #      end
  #    end
  #
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

  #task 'update:mi_attempts_bcm' => [:environment] do
  #  pp SolrUpdate::IndexProxy::Allele.get_uri
  #
  #  ApplicationModel.transaction do
  #    puts "#### enqueueing mi_attempts..."
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    counter = 0
  #    MiAttempt.all.each do |i|
  #      found = false
  #      i.distribution_centres.each do |distribution_centre|
  #        #pp distribution_centre
  #        if distribution_centre.centre.name == 'BCM'
  #          found = true
  #          break
  #        end
  #      end
  #
  #      next if ! found
  #    #  pp i.es_cell.allele.gene.marker_symbol
  #    #  exit
  #
  #      enqueuer.mi_attempt_updated(i)
  #      counter += 1
  #      #break if counter > 100
  #      #break
  #    end
  #
  #    puts "#### running mi_attempts (#{counter})..."
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

end

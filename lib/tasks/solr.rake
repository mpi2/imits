
require 'pp'

namespace :solr do
  desc 'Run the SOLR update queue to send recent changes to the index'
  task 'update' => [:environment] do
    SolrUpdate::Queue.run
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

      puts "#### enqueueing phenotype_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      PhenotypeAttempt.all.each { |p| enqueuer.phenotype_attempt_updated(p) }

      puts "#### enqueueing genes..."
      enqueuer = SolrUpdate::Enqueuer.new
      Gene.all.each { |g| enqueuer.gene_updated(g) }
    end
  end

  #desc 'Enqueue every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt for solr update'
  task 'update:partial_run' => [:environment] do

    pp SolrUpdate::IndexProxy::Allele.get_uri

    #exit

    ApplicationModel.transaction do

      puts "#### enqueueing mi_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }

      puts "#### running mi_attempts..."
      SolrUpdate::Queue.run(:limit => nil)

      #puts "#### enqueueing alleles..."
      #enqueuer = SolrUpdate::Enqueuer.new
      #TargRep::TargetedAllele.all.each { |a| enqueuer.allele_updated(a) }
      #
      #puts "#### running alleles..."
      #SolrUpdate::Queue.run(:limit => nil)

      puts "#### enqueueing phenotype_attempts..."
      enqueuer = SolrUpdate::Enqueuer.new
      PhenotypeAttempt.all.each { |p| enqueuer.phenotype_attempt_updated(p) }

      puts "#### running phenotype_attempts..."
      SolrUpdate::Queue.run(:limit => nil)

      #puts "#### enqueueing genes..."
      #enqueuer = SolrUpdate::Enqueuer.new
      #Gene.all.each { |g| enqueuer.gene_updated(g) }
      #
      #puts "#### running genes..."
      #SolrUpdate::Queue.run(:limit => nil)
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
end


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
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }

      puts "#### running mi_attempts..."
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
      TargRep::TargetedAllele.all.each { |a| enqueuer.allele_updated(a) }

      puts "#### running alleles..."
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:phenotype_attempts' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do

      puts "#### enqueueing phenotype_attempts..."

      enqueuer = SolrUpdate::Enqueuer.new
      counter = 0
      PhenotypeAttempt.all.each do |p|
        enqueuer.phenotype_attempt_updated(p)
        counter += 1
      end

      puts "#### running phenotype_attempts (#{counter})..."

      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  task 'update:genes' => [:environment] do
    pp SolrUpdate::IndexProxy::Allele.get_uri
    ApplicationModel.transaction do
      puts "#### enqueueing genes..."
      enqueuer = SolrUpdate::Enqueuer.new
      Gene.all.each { |g| enqueuer.gene_updated(g) }

      puts "#### running genes..."
      SolrUpdate::Queue.run(:limit => nil)
    end
  end

  desc 'Sync every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt with the SOLR index'
  task 'update:all_quick' => ['update:genes', 'update:phenotype_attempts', 'update:alleles', 'update:mi_attempts']

  desc 'Sync phenotype_attempts, mi_attempts'
  task 'update:some_quick' => ['update:phenotype_attempts', 'update:mi_attempts']

end

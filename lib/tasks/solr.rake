
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
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }
      
      enqueuer = SolrUpdate::Enqueuer.new
      TargRep::TargetedAllele.all.each { |a| enqueuer.allele_updated(a) }

      enqueuer = SolrUpdate::Enqueuer.new
      PhenotypeAttempt.all.each { |p| enqueuer.phenotype_attempt_updated(p) }
    end
  end

  #desc 'Enqueue every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt for solr update'
  #task 'update:all_run' => [:environment] do
  #  ApplicationModel.transaction do
  #    pp SolrUpdate::IndexProxy::Allele.get_uri
  #
  #    #enqueuer = SolrUpdate::Enqueuer.new
  #    #MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }
  #    #SolrUpdate::Queue.run(:limit => nil)
  #    #
  #    #enqueuer = SolrUpdate::Enqueuer.new
  #    #TargRep::TargetedAllele.all.each { |a| enqueuer.allele_updated(a) }
  #    #SolrUpdate::Queue.run(:limit => nil)
  #
  #    enqueuer = SolrUpdate::Enqueuer.new
  #    PhenotypeAttempt.all.each { |p| enqueuer.phenotype_attempt_updated(p) }
  #    SolrUpdate::Queue.run(:limit => nil)
  #  end
  #end

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

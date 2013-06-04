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
    end
  end

  task 'update:run_queue:all' => [:environment] do
    SolrUpdate::Queue.run(:limit => nil)
  end


  desc 'Sync every TargRep::TargetedAllele, TargRep::EsCell, MiAttempt & PhenotypeAttempt with the SOLR index'
  task 'update:all' => ['update:enqueue:all', 'update:run_queue:all']
end

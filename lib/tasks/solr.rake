namespace :solr do
  desc 'Enqueue every TargRep::Allele, TargRep::EsCell, MiAttempt & PhenotypeAttempt for solr update'
  task 'update:enqueue:all' => [:environment] do
    ApplicationModel.transaction do
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }

      enqueuer = SolrUpdate::Enqueuer.new
      TargRep::Allele.all.each { |a| enqueuer.allele_updated(a) }
    end
  end

  task 'update:run_queue:all' => [:environment] do
    SolrUpdate::Queue.run(:limit => nil)
  end


  desc 'Sync every TargRep::Allele, TargRep::EsCell, MiAttempt & PhenotypeAttempt with the SOLR index'
  task 'update:all' => ['update:enqueue:all', 'update:run_queue:all']
end

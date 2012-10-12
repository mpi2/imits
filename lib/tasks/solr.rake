namespace :solr do
  desc 'Sync every MiAttempt and PhenotypeAttempt with the SOLR index'
  task 'update:all' => [:environment] do
    ApplicationModel.transaction do
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }
    end
    SolrUpdate::Queue.run(:limit => nil)
  end
end

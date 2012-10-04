namespace :solr do
  desc 'Make the SOLR index up-to-date'
  task :update => [:environment] do
    ApplicationModel.transaction do
      MiAttempt.all.each { |i| SolrUpdate::Enqueuer.mi_attempt_updated(i) }
    end
    SolrUpdate::Queue.run
  end
end

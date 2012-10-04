namespace :solr do
  desc 'Make the SOLR index up-to-date'
  task :update => [:environment] do
    ApplicationModel.transaction do
      enqueuer = SolrUpdate::Enqueuer.new
      MiAttempt.all.each { |i| enqueuer.mi_attempt_updated(i) }
    end
    SolrUpdate::Queue.run
  end
end

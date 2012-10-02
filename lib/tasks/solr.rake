namespace :solr do
  desc 'Make the SOLR index up-to-date'
  task :update => [:environment] do
    ApplicationModel.transaction do
      MiAttempt.all.each { |i| SolrUpdate::Queue.enqueue_for_update(i) }
      PhenotypeAttempt.all.each { |i| SolrUpdate::Queue.enqueue_for_update(i) }
    end
    SolrUpdate::Queue.run
  end
end

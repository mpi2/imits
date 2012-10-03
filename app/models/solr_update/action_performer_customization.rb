module SolrUpdate::ActionPerformerCustomization
  def after_update(reference)
    if reference['type'] == 'mi_attempt'
      mi = MiAttempt.find(reference['id'])
      mi.phenotype_attempts.each do |pa|
        self.do({'type' => 'phenotype_attempt', 'id' => pa.id}, 'update')
      end
    end
  end
end

require 'solr_update/action_performer'

class SolrUpdate::ActionPerformer
  extend SolrUpdate::ActionPerformerCustomization
end

class SolrUpdate::DocFactory
  def self.create_for_mi_attempt(mi_attempt)
    solr_doc = {
      'id' => mi_attempt.id,
      'type' => 'mi_attempt',
      'mgi_accession_id' => mi_attempt.gene.mgi_accession_id
    }

    return solr_doc
  end
end

class SolrUpdate::DocFactory
  def self.create_for_mi_attempt(mi_attempt)
    solr_doc = {
      'id' => mi_attempt.id,
      'type' => 'mi_attempt'
    }

    if mi_attempt.gene.mgi_accession_id
      solr_doc['mgi_accession_id'] = mi_attempt.gene.mgi_accession_id
    end

    if mi_attempt.es_cell.mutation_subtype
      solr_doc['allele_type'] = mi_attempt.es_cell.mutation_subtype.titleize
    end

    if mi_attempt.colony_background_strain
      solr_doc['strain'] = mi_attempt.colony_background_strain.name
    end

    solr_doc['allele_name'] = mi_attempt.allele_symbol

    return solr_doc
  end
end

class Solr::Allele2 < Solr::Tableless
  attr_accessor :type, :allele_design_project, 
                :marker_symbol, :marker_mgi_accession_id, :marker_type, :marker_name, :marker_synonym,
                :human_gene_symbol, :human_entrez_gene_id, :human_homolo_gene_id,
                :feature_type, :feature_chromosome, :feature_strand, :feature_coord_start, :feature_coord_end,
                :genetic_map_links, :sequence_map_links, :gene_model_ids,
                :allele_symbol, :allele_name, :allele_type, :allele_mgi_accession_id, :mgi_accession_id, :synonym, :allele_symbol_search_variants,
                :allele_description, :design_id, :cassette, :ikmc_project, :pipeline,
                :allele_features, :without_allele_features, :mutation_type, :allele_category,
                :targeting_vector_available, :es_cell_available, :mouse_available,
                :genbank_file, :allele_image, :allele_simple_image, :vector_genbank_file, :vector_allele_image, :links,
                :es_cell_status, :mouse_status, :phenotype_status, :late_adult_phenotype_status, 
                :latest_es_cell_status, :latest_mouse_status, :latest_project_status_legacy, :latest_project_status, :latest_phenotype_status,
                :production_centre, :phenotyping_centre, :production_centres, :phenotyping_centres, :late_adult_phenotyping_centre, :late_adult_phenotyping_centres, 
                :latest_production_centre, :latest_phenotyping_centre,
                :latest_phenotype_started, :latest_phenotype_complete, :late_adult_phenotype_started, :late_adult_phenotype_complete,
                :fixed_tissues_available, :paraffin_embedded_sections_available, :tissue_types,
                :tissue_enquiry_links, :tissue_distribution_centres,
                :notes

  def cassette_type
    @cassette_type
  end

  def cassette_type=(arg)
    @cassette_type = cassette_type
  end

  def self.valid_blank_fields
    return [:allele_type]
  end
end

class Solr::Allele2 < Solr::Tableless
  attr_accessor :allele_design_project, :marker_symbol, :mgi_accession_id, :marker_type, :marker_name, 
                :synonym, :feature_type, :feature_chromosome, :feature_strand, :feature_coord_start, 
                :feature_coord_end, :es_cell_status, :mouse_status, :phenotype_status, :latest_es_cell_status, 
                :latest_mouse_status, :targeting_vector_available, :es_cell_available, :mouse_available, 
                :allele_symbol, :allele_symbol_search_variants, :allele_name, :mutation_type, :allele_category, 
                :allele_type, :allele_features, :without_allele_features, :allele_mgi_accession_id, :allele_description, 
                :genbank_file, :allele_image, :allele_simple_image, :vector_genbank_file, :vector_allele_image, 
                :type, :design_id, :cassette, :production_centre, :phenotyping_centre, :production_centres, 
                :phenotyping_centres, :latest_project_status_legacy, :latest_project_status, :ikmc_project, 
                :pipeline, :latest_production_centre, :latest_phenotyping_centre, :latest_phenotype_started, 
                :latest_phenotype_complete, :latest_phenotype_status, :notes, :genetic_map_links, :sequence_map_links, 
                :gene_model_ids, :links, :late_adult_phenotype_status, :late_adult_phenotyping_centre,
                :late_adult_phenotyping_centres, :late_adult_phenotype_started, :late_adult_phenotype_complete,
                :fixed_tissues_available, :paraffin_embedded_sections_available, :tissue_types,
                :tissue_enquiry_links, :tissue_distribution_centres

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

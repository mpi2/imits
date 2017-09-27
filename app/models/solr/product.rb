class Solr::Product < Solr::Tableless
  attr_accessor :allele_design_project, :product_id, 
                :marker_symbol, :marker_mgi_accession_id, :mgi_accession_id, :marker_type, :marker_name, :marker_synonym,
                :allele_mgi_accession_id, :allele_symbol, :name, :allele_type, :allele_name, :allele_has_issue, :allele_id, :type, :allele_synonym,
                :genetic_info, 
                :production_centre, 
                :production_pipeline, :production_completed, :production_info,
                :status, :status_date,  
                :qc_data, 
                :associated_product_colony_name, :associated_product_es_cell_name, :associated_product_vector_name, :associated_products_colony_names, :associated_products_es_cell_names, :associated_products_vector_names, 
                :order_names, :order_links, :contact_names, :contact_links, :other_links, :loa_assays,
                :ikmc_project_id, :design_id, :cassette

  def self.valid_blank_fields
    return [:allele_type]
  end
end

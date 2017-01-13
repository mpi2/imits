class Solr::Product < Solr::Tableless
  attr_accessor :allele_design_project, :product_id, :marker_symbol, :mgi_accession_id, :allele_type, :allele_name, :allele_has_issue, :allele_id, :type, :name, :genetic_info, :production_centre, :production_pipeline, :production_completed, :status, :status_date, :production_info, :qc_data, :associated_product_colony_name, :associated_product_es_cell_name, :associated_product_vector_name, :associated_products_colony_names, :associated_products_es_cell_names, :associated_products_vector_names, :order_names, :order_links, :contact_names, :contact_links, :other_links, :ikmc_project_id, :design_id, :cassette, :loa_assays, :allele_symbol

  def self.valid_blank_fields
    return [:allele_type]
  end
end

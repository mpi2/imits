# encoding: utf-8

class Rest::PhenotypingProductionSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    phenotype_attempt_id
    mi_plan_id
    marker_symbol
    mgi_accession_id
    consortium_name
    phenotyping_centre_name
    production_centre_name
    production_consortium_name
    production_colony_name
    mouse_allele_symbol
    parent_colony_background_strain_name
    colony_name
    rederivation_started
    rederivation_complete
    colony_background_strain_name
    phenotyping_experiments_started
    phenotyping_started
    phenotyping_complete
    report_to_public
    is_active
    ready_for_website
    cohort_production_centre_name
    status_name
}

  def initialize(phenotyping_production)
    @phenotyping_production = phenotyping_production
  end

  def as_json
    json_hash = super(@phenotyping_production)

    return json_hash
  end

end

# encoding: utf-8

class Grid::MiPlanSerializer

  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    marker_symbol
    mgi_accession_id
    consortium_name
    production_centre_name
    sub_project_name
    status_name
    priority_name
    mutagenesis_via_crispr_cas9
    phenotype_only
    withdrawn
    is_active
    is_bespoke_allele
    is_conditional_allele
    is_deletion_allele
    is_cre_knock_in_allele
    is_cre_bac_allele
    conditional_tm1c
    recovery
    point_mutation
    conditional_point_mutation
    ignore_available_mice
  }

  def initialize(mi_plan, options = {})
    @options = options
    @mi_plan = mi_plan
  end

  def as_json
    json_hash = super(@mi_plan, @options)
    return json_hash
  end
end

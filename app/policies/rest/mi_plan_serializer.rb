# encoding: utf-8

class Rest::MiPlanSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    marker_symbol
    mgi_accession_id
    consortium_name
    production_centre_name
    sub_project_name
    priority_name
    mutagenesis_via_crispr_cas9
    phenotype_only
    withdrawn
    is_active
    number_of_es_cells_starting_qc
    number_of_es_cells_passing_qc
    number_of_es_cells_received
    es_cells_received_on
    es_cells_received_from_id
    es_cells_received_from_name
    is_bespoke_allele
    is_conditional_allele
    is_deletion_allele
    is_cre_knock_in_allele
    is_cre_bac_allele
    conditional_tm1c
    recovery
    point_mutation
    conditional_point_mutation
    es_qc_comment_name
    comment
    ignore_available_mice
    completion_note
    completion_comment
    report_to_public
    status_name
    status_dates
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

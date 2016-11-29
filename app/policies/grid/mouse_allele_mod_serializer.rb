# encoding: utf-8

class Grid::MouseAlleleModSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    phenotype_attempt_id
    mi_plan_id
    consortium_name
    production_centre_name
    status_name
    mi_attempt_colony_name
    no_modification_required
    cre_excision_required
    colony_name
    rederivation_started
    rederivation_complete
    number_of_cre_matings_successful
    mouse_allele_type
    deleter_strain_name
    colony_background_strain_name
    tat_cre
    report_to_public
    is_active
}

  def initialize(mouse_allele_mod, options = {})
    @options = options
    @mouse_allele_mod = mouse_allele_mod
  end

  def as_json
    json_hash = super(@mouse_allele_mod, @options)
    return json_hash
  end
end

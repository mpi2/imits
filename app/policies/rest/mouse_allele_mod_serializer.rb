# encoding: utf-8

class Rest::MouseAlleleModSerializer
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

  def initialize(mouse_allele_mod)
    @mouse_allele_mod = mouse_allele_mod
    @colony = mouse_allele_mod.colony
    @distribution_centres = @colony.distribution_centres
  end

  def as_json
    json_hash = super(@mouse_allele_mod)
    json_hash['distribution_centres'] = distribution_centres_attributes

    return json_hash
  end

  def distribution_centres_attributes
    distribution_centres_hash = []
    @distribution_centres.each do |distribution_centre|
      distribution_centres_hash << Rest::DistributionCentreSerializer.new(distribution_centre).as_json
    end

    return distribution_centres_hash
  end
end

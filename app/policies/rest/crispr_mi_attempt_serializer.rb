# encoding: utf-8

class Rest::CrisprMiAttemptSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    external_ref
    mi_date
    mi_plan_id
    marker_symbol 
    mgi_accession_id
    consortium_name
    production_centre_name
    parent_colony_name
    blast_strain_name
    blast_strain_mgi_accession
    blast_strain_mgi_name    
    mrna_nuclease
    mrna_nuclease_concentration
    protein_nuclease
    protein_nuclease_concentration
    delivery_method
    voltage
    number_of_pulses 
    crsp_total_embryos_injected
    crsp_total_embryos_survived
    crsp_total_transfered
    crsp_no_founder_pups
    founder_num_assays
    assay_type
    crsp_embryo_transfer_day 
    crsp_embryo_2_cell 
    crsp_num_founders_selected_for_breading
    privacy
    report_to_public
    is_active
    experimental
    status_name
    status_dates
  }

  def initialize(mi_attempt)
    @mi_attempt = mi_attempt
    @colonies = mi_attempt.colonies
    @mutagenesis_factors = mi_attempt.mutagenesis_factor
    @reagents = mi_attempt.reagents
  end

  def as_json
    json_hash = super(@mi_attempt)

#    json_hash['mutagenesis_factor_attributes'] = mutagenesis_factor_attributes
    json_hash['reagents_attributes'] = reagents_attributes
#    json_hash['g0_screens_attributes'] = g0_screens_attributes
    json_hash['colonies_attributes'] = colonies_attributes

    return json_hash
  end

  def colonies_attributes
    colonies_hash = []
    @colonies.each do |colony|
      colonies_hash << Rest::ColonySerializer.new(colony).as_json
    end

    return colonies_hash
  end

  def reagents_attributes
    reagents_hash = []
    @reagents.each do |reagent|
      reagents_hash << Rest::ReagentSerializer.new(reagent).as_json
    end

    return reagents_hash
  end

  def mutagenesis_factor_attributes
    mutagenesis_factor_hash = []
    [@mutagenesis_factors].each do |mutagenesis_factor|
      mutagenesis_factor_hash << Rest::MutagenesisFactorSerializer.new(mutagenesis_factor).as_json
    end

    return mutagenesis_factor_hash
  end

  def g0_screens_attributes
    g0_screens_hash = []
    [@mutagenesis_factors].each do |g0_screen|
      g0_screens_hash << Rest::G0ScreenSerializer.new(g0_screen).as_json
    end

    return g0_screens_hash
  end

end

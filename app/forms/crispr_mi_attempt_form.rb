# encoding: utf-8
class CrisprMiAttemptForm
  include ApplicationForm::AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    external_ref
    mi_date
    mi_plan_id
    marker_symbol 
    consortium_name
    production_centre_name
    parent_colony_name
    blast_strain_name    
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
  }

  WRITABLE_ATTRIBUTES.each do |attr|
    define_method(attr) do
        if @params.has_key?(attr)
          return @params[attr]
        else
          @form_model.send(attr)
      end
    end
  end

  def initialize(mi_attempt, params)
  	raise 'Please provide model and params' if mi_attempt.blank? || params.blank?
    filter_parmas(params)

  	@form_model = mi_attempt
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models
    @colonies = []
    @mutagenesis_factor = []

    # params received
  	@params = params

    process_attributes_params
  end

  def filter_parmas(params)
    params.delete('g0_screens_attributes')
  end

end

# encoding: utf-8
class MutagenesisFactorForm
  include AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    external_ref
    individually_set_grna_concentrations
    guides_generated_in_plasmid
    grna_concentration
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

  def initialize(mutagenesis_factor, params)
  	raise 'Please provide model and params' if mutagenesis_factor.blank? || params.blank?
  	@form_model = mutagenesis_factor
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models
      crisprs = []
      vectors = []
      genotype_primers = []

    # params received
  	@params = params

    process_attributes_params
  end

end

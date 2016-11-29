# encoding: utf-8
class ColonyForm
  include AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    name
    genotype_confirmed
    background_strain_name
    allele_symbol
    mgi_allele_symbol_superscript
    mgi_allele_symbol_without_impc_abbreviation
    mgi_allele_id
    report_to_public
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

  def initialize(colony, params)
  	raise 'Please provide model and params' if colony.blank? || params.blank?
  	@form_model = colony
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models
    @distribution_centres = []

    # params received
  	@params = params

    process_attributes_params
  end

end

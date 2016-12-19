# encoding: utf-8
class CrisprForm

  WRITABLE_ATTRIBUTES = %w{
    sequence
    chr
    start
    end
    grna_concentration
    individually_set_grna_concentrations
    guides_generated_in_plasmid
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

  def initialize(crispr, params)
  	raise 'Please provide model and params' if crispr.blank? || params.blank?
  	@form_model = crispr
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models

    # params received
  	@params = params

  end

end

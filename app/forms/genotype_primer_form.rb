# encoding: utf-8
class GenotypePrimerForm
  include AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    sequence
    name
    genomic_start_coordinate
    genomic_end_coordinate
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

  def initialize(genotype_primer, params)
  	raise 'Please provide model and params' if genotype_primer.blank? || params.blank?
  	@form_model = genotype_primer
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models

    # params received
  	@params = params

  end

end

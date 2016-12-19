# encoding: utf-8
class VectorForm

  WRITABLE_ATTRIBUTES = %w{
    vector_name
    concentration
    preparation
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

  def initialize(vector, params)
  	raise 'Please provide model and params' if vector.blank? || params.blank?
  	@form_model = vector
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models

    # params received
  	@params = params

  end

end

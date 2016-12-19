# encoding: utf-8
class DistributionCentreForm

  WRITABLE_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    distribution_network
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

  def initialize(distribution_centre, params)
  	raise 'Please provide model and params' if distribution_centre.blank? || params.blank?
  	@form_model = distribution_centre
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models

    # params received
  	@params = params

  end

end

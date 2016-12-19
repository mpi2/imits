module ApplicationForm::AcceptNestedAttributes

  def process_attributes_params
    @params.select{|p| p =~ /attributes/}.each do |attributes_key, attributes_params|
    
      model_hash = {}

      md = /\A(\w+)_attributes\Z/.match(attributes_key)
      model_attribute = md[1]
      model_objects = @form_model.send(model_attribute)
  
      if model_objects.is_a?(Array)
        # iterate
        model_objects.each{|mo| model_hash[mo.id] = mo}
        attributes_params.each do |p_attr|
          # attributes_params is either a hash or an array. Therefore need to check p_attr type.
          attributes = p_attr.is_a?(Array) ? p_attr.last : p_attr
          model = p_attr.has_key?('id') ? model_hash[p_attr['id']] : nil
          create_associated_form(model_attribute, model, attributes)
        end
      else
        # do not iterate
        next if attributes_params.is_a?(Array)
        
        model_hash[model_objects.id] = model_objects
        model = p_attr.has_key?('id') ? model_hash[p_attr['id']] : nil
        create_associated_form(model_attribute, model, attributes_params)
      end
    end
  end
  protected :process_attributes_params
  
  def create_associated_form(model_attribute, model, attributes)
    model_name = ActiveSupport::Inflector.singularize(model_attribute.camelcase)
    form_object = "#{model_name}Form".constantize
    model = @form_model.send(model_attribute).new if model.blank?
  
    instance_variable_get("@#{model_attribute}") << form_object.new(model, attributes) 
  end
  protected :create_associated_form

end

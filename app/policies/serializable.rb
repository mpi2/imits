module Serializable
  def as_json(model, options = {}, &add_additional_attributes)
    access_private_attributes = options[:access_private_attributes] || false
    use_default = options[:default] || false

    if use_default
      serialized_hash = model.as_json(options)
    else
      serialized_hash = model.as_json(default_serializer_options(model, options))
    end

    add_additional_attributes.call(serialized_hash) unless add_additional_attributes.nil?

    if model.class.attribute_method?(:private) && model.private == true && access_private_attributes == false
      raise 'PRIVATE_ATTRIBUTES must be set in model' unless model.class.const_get('PRIVATE_ATTRIBUTES')

      model.class.const_get('PRIVATE_ATTRIBUTES').each do |private_attr|
        next unless serialized_hash.has_key?(private_attr)
        if serialized_hash[private_attr].is_a?(Array)
          serialized_hash[private_attr] = []
        else
          serialized_hash[private_attr] = nil
        end
      end
    end

    return serialized_hash
  end

  def default_serializer_options(model, options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] = self.class.const_get('JSON_ATTRIBUTES') - model.attribute_names # get constant from class this is included into, not the module it is defined in
    options[:only] = model.attribute_names & self.class.const_get('JSON_ATTRIBUTES')
    return options
  end
  private :default_serializer_options

end

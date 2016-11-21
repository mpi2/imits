module Serializable
  def as_json(model, options = {})
    use_default = options[:default] || false
    return model.as_json(options) if use_default
    return model.as_json(default_serializer_options(model, options))
  end

  def to_xml(model, options = {})
    use_default = options[:default] || false
    options[:dasherize] = false
    return model.to_xml(options) if use_default
    return model.to_xml(default_serializer_options(model, options))
  end

  private

  def default_serializer_options(model, options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] = self.class.const_get('JSON_ATTRIBUTES') - model.attribute_names # get constant from class this is included into, not the module it is defined in
    options[:only] = model.attribute_names & self.class.const_get('JSON_ATTRIBUTES')
    return options
  end

end

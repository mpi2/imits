module Public::Serializable
  def as_json(options = {})
    use_default = options[:default] || false
    return super(options) if use_default
    return super(default_serializer_options(options))
  end

  def to_xml(options = {})
    use_default = options[:default] || false
    options[:dasherize] = false
    return super(options) if use_default
    return super(default_serializer_options(options))
  end

  private

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] = self.class.const_get('READABLE_ATTRIBUTES') - attribute_names # get constant from class this is included into, not the module it is defined in
    options[:only] = attribute_names & self.class.const_get('READABLE_ATTRIBUTES')
    return options
  end

  end

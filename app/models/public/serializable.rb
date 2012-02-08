module Public::Serializable
  def as_json(options = {})
    return super(default_serializer_options(options))
  end

  def to_xml(options = {})
    options[:dasherize] = false
    return super(default_serializer_options(options))
  end

  private

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] = self.class.const_get('READABLE_ATTRIBUTES') # get constant from class this is included into, not the module it is defined in
    options[:only] = options[:methods]
    return options
  end

  end

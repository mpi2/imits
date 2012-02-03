module Public::Serializable
    def as_json(options = {})
    options ||= {}
    options.symbolize_keys!

    options[:methods] = self.class.const_get('READABLE_ATTRIBUTES') # get constant from class this is included into, not the module it is defined in
    options[:only] = options[:methods]
    return super(options)
  end
end

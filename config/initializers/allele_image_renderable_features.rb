class Hash

  def recursively_symbolize_keys!
    self.keys.each do |k|
      next unless k.is_a?(String)
      ks    = k.respond_to?(:to_sym) ? k.to_sym : k
      self[ks] = self.delete k # Preserve order even when k == ks
      self[ks].recursively_symbolize_keys! if self[ks].kind_of? Hash
    end

    self
  end

  def recursively_downcase_keys!
    self.keys.each do |k|
      next unless k.is_a?(String)
      ks    = k.downcase
      self[ks] = self.delete k # Preserve order even when k == ks
      self[ks].recursively_downcase_keys! if self[ks].kind_of? Hash
    end

    self
  end

end

RENDERABLE_FEATURES2 = AlleleImage2::RenderableFeatures.load_yaml unless Rails.env.development?
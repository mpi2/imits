# encoding: utf-8

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def self.translate_search_param(translations, param)
    translations.each do |tr_from, tr_to|
      md = /^#{tr_from}_(.+)$/.match(param)
      if md
        return "#{tr_to}_#{md[1]}"
      end
    end

    return param
  end

  def self.public_search(params)
    translated_params = {}
    params.stringify_keys.each do |name, value|
      translated_params[translate_search_param(name)] = value
    end
    return self.search(translated_params)
  end

end

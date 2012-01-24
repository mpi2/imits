# encoding: utf-8

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  def self.translations
    return {}
  end

  def self.translate_public_param(param)
    translations.each do |tr_from, tr_to|
      md = /^#{tr_from}(_| )(.+)$/.match(param)
      if md
        return "#{tr_to}#{md[1]}#{md[2]}"
      end
    end

    return param
  end

  def self.public_search(params)
    params = params.dup.stringify_keys
    translated_params = {}

    sorts = translate_public_param(params.delete('sorts')) unless params['sorts'].blank?
    params.each do |name, value|
      translated_params[translate_public_param(name)] = value
    end
    return self.search(translated_params.merge('sorts' => sorts))
  end

end

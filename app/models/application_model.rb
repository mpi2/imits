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

    sorts = params.delete('sorts')
    unless sorts.blank?
      translated_params['sorts'] = translate_public_param(sorts)
    end

    params.each do |name, value|
      translated_params[translate_public_param(name)] = value
    end

    return self.search(translated_params)
  end

  def consortium_name_and_production_centre_name_from_mi_plan_validation
    {
      :consortium_name => Consortium,
      :production_centre_name => Centre
    }.each do |attr, klass|
      value = send(attr)
      next if value.blank?
      association_name = attr.to_s.gsub('_name', '')

      if mi_plan and mi_plan.send(association_name) and value != mi_plan.send(association_name).name
        errors.add attr, 'cannot be changed'
      else
        associated = klass.find_by_name(value)
        if associated.blank?
          errors.add attr, 'does not exist'
        end
      end
    end
  end

  def as_json(options = {})
    options ||= {}
    options.symbolize_keys!

    options[:methods] = READABLE_ATTRIBUTES
    options[:only] = options[:methods]
    return super(options)
  end

end

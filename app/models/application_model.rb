# encoding: utf-8

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  MOUSE_ALLELE_OPTIONS = {
    nil => '[none]',
    'a' => 'a - Knockout-first - Reporter Tagged Insertion',
    'b' => 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion',
    'c' => 'c - Knockout-First, Post-Flp - Conditional',
    'd' => 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter',
    'e' => 'e - Targeted Non-Conditional'
  }.freeze

  # BEGIN Callbacks

  before_validation :set_blank_strings_to_nil

  protected

  def set_blank_strings_to_nil
    self.attributes.each do |name, value|
      if self[name].respond_to?(:to_str) && self[name].blank?
        self[name] = nil
      end
    end
  end

  public

  # END Callbacks


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

  def self.audited_transaction
    ActiveRecord::Base.transaction do
      Audit.as_user(User.find_by_email! 'htgt@sanger.ac.uk') do
        yield
      end
    end
  end

end

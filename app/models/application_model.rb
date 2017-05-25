# encoding: utf-8

class ApplicationModel < ActiveRecord::Base
  self.abstract_class = true

  COMPLETION_NOTE ={
    nil => '[none]',
    'Handoff complete' => 'Handoff complete',
    'Allele not needed' => 'Allele not needed',
    'Effort concluded' => 'Effort concluded'
  }.freeze

  # BEGIN Callbacks

  before_validation :set_blank_strings_to_nil

  protected

  def set_blank_strings_to_nil
    self.attributes.each do |name, value|
      if self[name].respond_to?(:to_str) && self[name].blank? && !self.class.allowed_to_be_blank.include?(name)
        self[name] = nil
      end
    end
  end

  public

  # END Callbacks

  def self.allowed_to_be_blank
    return []
  end
  
  def self.translations
    return {}
  end

  def self.translate_public_param(param)
    translations.each do |tr_from, tr_to|
      md = /^#{tr_from}(_| |$)(.*)$/.match(param)
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

    verify_translated_params = translated_params.dup
    verify_translated_params.delete('sorts')
    verify_translated_params.delete('extended_response')

    ##
    ## We need to detect situations in which ransack does not apply any conditions and the users *are*
    ## requesting data using invalid conditions.
    ##
    search_object = self.search(translated_params)

    if !verify_translated_params.empty? && search_object.conditions.empty?
      ##
      ## This nil needs to be handled on the other end.
      ## The old implementation expects a ransack dataset.
      ##
      return nil
    end

    return search_object
  end

  def self.audited_transaction
    ActiveRecord::Base.transaction do
      Audit.as_user(User.find_by_email! 'htgt@sanger.ac.uk') do
        yield
      end
    end
  end

  def self.to_public_class
    return "Public::#{self.name}".constantize
  end

  def to_public
    return self.class.to_public_class.find(self.id)
  end
end

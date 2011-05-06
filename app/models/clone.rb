# encoding: utf-8

class Clone < ActiveRecord::Base
  TEMPLATE_CHARACTER = '@'

  belongs_to :pipeline
  has_many :mi_attempts

  validates :clone_name, :presence => true, :uniqueness => true
  validates :marker_symbol, :presence => true
  validates :allele_name_superscript_template, :presence => true
  validates :pipeline, :presence => true

  def allele_name_superscript
    if derivative_allele_suffix
      return allele_name_superscript_template.sub(TEMPLATE_CHARACTER, derivative_allele_suffix)
    else
      return allele_name_superscript_template
    end
  end

  class AlleleNameSuperscriptFormatUnrecognizedError < RuntimeError; end

  def allele_name_superscript=(text)
    re = /\A(tm\d)([a-e])?(\(\w+\)\w+)\Z/

    md = re.match(text)

    if ! md
      raise AlleleNameSuperscriptFormatUnrecognizedError, "Bad allele name superscript #{text}"
    end

    if md[2].blank?
      self.allele_name_superscript_template = md[1] + md[3]
      self.derivative_allele_suffix = nil
    else
      self.allele_name_superscript_template = md[1] + TEMPLATE_CHARACTER + md[3]
      self.derivative_allele_suffix = md[2]
    end
  end

  def allele_name
    return "#{marker_symbol}<sup>#{allele_name_superscript}</sup>"
  end

end


# == Schema Information
#
# Table name: clones
#
#  id                               :integer         not null, primary key
#  clone_name                       :text            not null
#  marker_symbol                    :text            not null
#  allele_name_superscript_template :text            not null
#  derivative_allele_suffix         :text
#  pipeline_id                      :integer         not null
#  created_at                       :datetime
#  updated_at                       :datetime
#


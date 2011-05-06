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
end

# == Schema Information
#
# Table name: clones
#
#  id                      :integer         not null, primary key
#  clone_name              :text            not null
#  marker_symbol           :text            not null
#  allele_name_superscript :text            not null
#  pipeline_id             :integer         not null
#  created_at              :datetime
#  updated_at              :datetime
#


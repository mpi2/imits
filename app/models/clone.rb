class Clone < ActiveRecord::Base
  belongs_to :pipeline
  has_many :mi_attempts

  validates :clone_name             , :presence => true, :uniqueness => true
  validates :marker_symbol          , :presence => true
  validates :allele_name_superscript, :presence => true
  validates :pipeline               , :presence => true
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


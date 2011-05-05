class Clone < ActiveRecord::Base
  belongs_to :pipeline
  has_many :mi_attempts

  validates :clone_name             , :presence => true, :uniqueness => true
  validates :marker_symbol          , :presence => true
  validates :allele_name_superscript, :presence => true
  validates :pipeline               , :presence => true
end

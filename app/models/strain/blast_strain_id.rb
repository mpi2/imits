class Strain::BlastStrainId < ActiveRecord::Base
  attr_accessible :id
  belongs_to :strain, :foreign_key => :id

  delegate :name, :to => :strain
end

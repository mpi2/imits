class Strain::TestCrossStrainId < ActiveRecord::Base
  attr_accessible :id
  belongs_to :strain, :foreign_key => :id
end

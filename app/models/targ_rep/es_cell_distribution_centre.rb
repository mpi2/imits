class TargRep::EsCellDistributionCentre < ActiveRecord::Base

  ## Relationships
  has_many :distribution_qcs, :class_name => "TargRep::DistributionQc"
  has_many :users
  
  ## Validations
  validates :name,
    :uniqueness => {:message => 'This Centre name has already been taken'},
    :presence => true
end

# == Schema Information
#
# Table name: targ_rep_es_cell_distribution_centres
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#


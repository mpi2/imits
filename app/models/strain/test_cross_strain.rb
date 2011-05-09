class Strain::TestCrossStrain < ActiveRecord::Base
  attr_accessible :id
  belongs_to :strain, :foreign_key => :id

  delegate :name, :to => :strain
end

# == Schema Information
#
# Table name: strain_test_cross_strain_ids
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#


class Strain::TestCrossStrain < ActiveRecord::Base
  attr_accessible :id
  belongs_to :strain, :foreign_key => :id

  delegate :name, :to => :strain
end


# == Schema Information
# Schema version: 20110421150000
#
# Table name: strain_test_cross_strains
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#


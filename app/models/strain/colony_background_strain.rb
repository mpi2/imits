class Strain::ColonyBackgroundStrain < ActiveRecord::Base
  acts_as_reportable

  attr_accessible :id
  belongs_to :strain, :foreign_key => :id

  delegate :name, :to => :strain
end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: strain_colony_background_strains
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_strain_colony_background_strains_on_id  (id) UNIQUE
#

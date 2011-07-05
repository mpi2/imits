class Strain::ColonyBackgroundStrain < Strain::Base
  define_interface
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


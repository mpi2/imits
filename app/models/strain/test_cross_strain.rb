class Strain::TestCrossStrain < Strain::Base
  define_interface
end

# == Schema Information
# Schema version: 20110802094958
#
# Table name: strain_test_cross_strains
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_strain_test_cross_strains_on_id  (id) UNIQUE
#


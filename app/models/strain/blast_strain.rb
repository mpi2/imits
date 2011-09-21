class Strain::BlastStrain < Strain::Base
  define_interface
end

# == Schema Information
# Schema version: 20110921000000
#
# Table name: strain_blast_strains
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_strain_blast_strains_on_id  (id) UNIQUE
#


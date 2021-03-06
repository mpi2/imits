class DeleterStrain < ActiveRecord::Base
  acts_as_reportable

  validates :name, :uniqueness => true
  validates :excision_type, :presence => true

  has_many :mouse_allele_mods
end

# == Schema Information
#
# Table name: deleter_strains
#
#  id            :integer          not null, primary key
#  name          :string(100)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  excision_type :string(255)
#

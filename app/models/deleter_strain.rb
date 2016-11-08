class DeleterStrain < ActiveRecord::Base
  acts_as_reportable
  attr_accessible

  validates :name, :uniqueness => true
  validates :excision_type, :presence => true

  has_many :phenotype_attempt
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

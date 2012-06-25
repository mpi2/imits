class DeleterStrain < ActiveRecord::Base
  acts_as_reportable

  validates :name, :uniqueness => true

  has_many :phenotype_attempt
end

# == Schema Information
#
# Table name: deleter_strains
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#


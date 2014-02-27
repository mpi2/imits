class TargRep::MutationSubtype < ActiveRecord::Base
  
  acts_as_audited

  has_many :allele

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true

end

# == Schema Information
#
# Table name: targ_rep_mutation_subtypes
#
#  id         :integer          not null, primary key
#  name       :string(100)      not null
#  code       :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

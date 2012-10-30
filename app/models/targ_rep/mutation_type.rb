class TargRep::MutationType < ActiveRecord::Base
  
  acts_as_audited

  has_many :allele, :class_name => "TargRep::Allele"

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true


  def targeted_non_conditional?
    if self.code == 'tnc'
      true
    else
      false
    end
  end

  def no_loxp_site?
    if !['crd', 'cki'].include?(self.code)
      true
    else
      false
    end
  end

end

# == Schema Information
#
# Table name: targ_rep_mutation_types
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  code       :string(100)     not null
#  created_at :datetime
#  updated_at :datetime
#


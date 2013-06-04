class TargRep::MutationType < ActiveRecord::Base
  
  acts_as_audited

  has_many :allele

  validates :name, :presence => true, :uniqueness => true
  validates :code, :presence => true, :uniqueness => true


  def targeted_non_conditional?
    self.code == 'tnc'
  end

  def no_loxp_site?
    !['crd', 'cki'].include?(self.code)
  end

  def gene_trap?
    self.code == 'gt'
  end

  def self.gene_trap_name
    self.where(:code => 'gt').first.name
  end

end

# == Schema Information
#
# Table name: targ_rep_mutation_types
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  code       :string(100)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#


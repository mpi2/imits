class TargRep::RealAllele < ActiveRecord::Base
  acts_as_audited

  before_validation :check_type

  ## Validations
  validates                 :gene_id,           :presence => true
  validates                 :allele_name,       :presence => true
  validates                 :allele_type,       :presence => true

  validates_uniqueness_of   :gene_id,
    :scope => [
      :allele_name
    ],
    :message => "must have a unique combination of gene id and allele name"

  validates_inclusion_of :allele_type,
    :in => ['a','b','c','d','e','e.1','1'],
    :message => "Allele Type can only be 'a','b','c','d','e','e.1' or '1'"


  def check_type 
    unless :allele_name.blank?
      allele_type_array = /\A(tm\d+)([a-e]|.\d+)?(\(\w+\)\w+)\Z/.match(:allele_name)

      if allele_type_array
        self.allele_type = allele_type_array[2]
      else
        self.allele_type = empty
      end
    end
  end
end

# == Schema Information
#
# Table name: targ_rep_real_alleles
#
#  id          :integer          not null, primary key
#  gene_id     :integer          not null
#  allele_name :string(20)       not null
#  allele_type :string(10)       not null
#
# Indexes
#
#  real_allele_logical_key  (gene_id,allele_name) UNIQUE
#

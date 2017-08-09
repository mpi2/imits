class MutagenesisAllele < ActiveRecord::Base

  acts_as_audited
  acts_as_reportable

  belongs_to :allele
  belongs_to :mutagenesis_factor

### VALIDATION METHODS

  validate :allele, :presence => true
  validate :mutagenesis_factor, :presence => true

end

# == Schema Information
#
# Table name: mutagenesis_alleles
#
#  id                    :integer          not null, primary key
#  allele_id             :integer          not null
#  mutagenesis_factor_id :integer          not null
#

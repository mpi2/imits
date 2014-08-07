class TargRep::GenotypePrimer < ActiveRecord::Base
  acts_as_audited

  attr_accessible :mutagensis_factor_id, :sequence, :name, :genomic_start_coordinate, :genomic_end_coordinate, :allele_id

  belongs_to :mutagenesis_factor
  belongs_to :allele

  before_validation :upper_case_sequence

  validates_presence_of :sequence

  def upper_case_sequence
    self.sequence = self.sequence.upcase if !self.sequence.blank?
  end
  protected :upper_case_sequence
end

# == Schema Information
#
# Table name: targ_rep_genotype_primers
#
#  id                       :integer          not null, primary key
#  sequence                 :string(255)      not null
#  name                     :string(255)
#  genomic_start_coordinate :integer
#  genomic_end_coordinate   :integer
#  mutagenesis_factor_id    :integer
#  allele_id                :integer
#

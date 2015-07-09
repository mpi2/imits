class ColonyAllele < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :colony
  belongs_to :gene_target
  belongs_to :real_allele

  has_one :trace_call
  has_one :colony_qc

  validates :colony, :presence => true
  validates :gene_target, :presence => true

  validate do |ca|
    other_ids = ColonyAllele.where(:colony_id => ca.colony_id,
      :gene_target_id => ca.gene_target_id).map(&:id)
    other_ids -= [ca.id]
    if(other_ids.count != 0)
      ca.errors.add(:colony, "Can only have one allele per gene")
    end
  end

  def mutagenesis_factor
    gene_target.try(:mutagenesis_factor)
  end

  def es_cell
    mi_attempt.try(:es_cell)
  end

  def mi_attempt
    gene_target.try(:mi_attempt)
  end

  def gene
    gene_target.mi_plan.try(:gene)
  end

end

# == Schema Information
#
# Table name: colony_alleles
#
#  id             :integer          not null, primary key
#  colony_id      :integer          not null
#  gene_target_id :integer
#  real_allele_id :integer
#

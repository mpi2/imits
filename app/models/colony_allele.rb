class ColonyAllele < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :colony
  belongs_to :mutagenesis_factor

  has_one :colony_qc

  validates :colony, :presence => true


  validate do |ca|

    if !es_cell.blank? && !mutagenesis_factor_id.blank?
      ca.errors.add(:mutagenesis_factor, "must not be set for ES Cell Micro-Injections")
    end

    if es_cell.blank? && mutagenesis_factor_id.blank?
      ca.errors.add(:mutagenesis_factor, "must be set for CRISPR mediated Micro-Injections")
    end

    other_ids = ColonyAllele.where(:colony_id => ca.colony_id,
      :mutagenesis_factor_id => ca.mutagenesis_factor_id).map(&:id)
    other_ids -= [ca.id]
    if(other_ids.count != 0)
      ca.errors.add(:colony, "Can only have one allele per Mutagenesis Factor")
    end
  end


  def gene_target
    mutagenesis_factor.gene_target
  end

  def es_cell
    mi_attempt.try(:es_cell)
  end

  def mi_attempt
    colony.try(:mi_attempt)
  end

  def gene
    if !es_cell.blank?
      mi_attempt.gene_target.mi_plan.try(:gene)
    else
      gene_target.mi_plan.try(:gene)
    end
  end

end

# == Schema Information
#
# Table name: colony_alleles
#
#  id                    :integer          not null, primary key
#  colony_id             :integer          not null
#  mutagenesis_factor_id :integer
#

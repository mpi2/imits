# encoding: utf-8

class GeneTarget < ApplicationModel
  include ApplicationModel::BelongsToMiPlan

  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include ApplicationModel::BelongsToMiPlan

  belongs_to :mi_plan
  belongs_to :mi_attempt
  belongs_to :mutagenesis_factor

  has_many   :colony_alleles


  validates :mi_plan, :presence => true
  validates :mi_attempt, :presence => true

  validate do |gt|
    other_ids = GeneTarget.where(:mi_attempt_id => gt.mi_attempt_id,
      :mi_plan_id => gt.mi_plan_id).map(&:id)
    other_ids -= [gt.id]
    if(other_ids.count != 0)
      gt.errors.add(:mi_attempt, "Can only target each gene once. #{mi_plan.marker_symbol} has been targeted multiple times")
    end
  end

  # validate mi plan
  validate do |gt|
    if validate_plan #test whether to continue with validations
      if mi_plan.phenotype_only
        gt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (phenotype only)')
      end
      if mi_plan.mutagenesis_via_crispr_cas9 and !mi_attempt.es_cell.blank?
        gt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (crispr plan)')
      end

      if !mi_plan.mutagenesis_via_crispr_cas9 and !mutagenesis_factor.blank?
        gt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (requires crispr plan)')
      end
    end
  end

  def marker_symbol
    return mi_plan.gene.try(:marker_symbol)
    return nil
  end

end

# == Schema Information
#
# Table name: gene_targets
#
#  id                    :integer          not null, primary key
#  mi_plan_id            :integer          not null
#  mi_attempt_id         :integer          not null
#  mutagenesis_factor_id :integer
#

class ColonyAllele < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :colony
  belongs_to :gene_target

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

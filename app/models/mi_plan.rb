# encoding: utf-8

class MiPlan < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute

  belongs_to :gene
  belongs_to :consortium
  belongs_to :mi_plan_status
  belongs_to :mi_plan_priority
  belongs_to :production_centre, :class_name => 'Centre'

  has_many :mi_attempts

  validates :gene, :presence => true
  validates :consortium, :presence => true
  validates :mi_plan_status, :presence => true
  validates :mi_plan_priority, :presence => true

  validates_uniqueness_of :gene_id, :scope => [:consortium_id, :production_centre_id]

  def self.with_mi_attempt
    where('mi_plans.id in (?)', MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id))
  end

  def self.without_mi_attempt
    where('mi_plans.id not in (?)', MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id))
  end

  def self.with_active_mi_attempt
    where('mi_plans.id in (?)', MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id))
  end

  def self.without_active_mi_attempt
    where('mi_plans.id not in (?)', MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id))
  end

  def self.assign_genes_and_mark_conflicts
    conflict_status = MiPlanStatus.find_by_name!('Conflict')
    declined_due_to_conflict_status = MiPlanStatus.find_by_name!('Declined - Conflict')
    declined_due_to_mi_attempt_status = MiPlanStatus.find_by_name!('Declined - MI Attempt')

    self.all_grouped_by_mgi_accession_id_then_by_status_name.each do |mgi_accession_id, mi_plans_by_status|
      interested = mi_plans_by_status['Interest']

      next if interested.blank?

      if ! mi_plans_by_status['Assigned'].blank?
        assigned_plans_with_mis = MiPlan.where('id in (?)', mi_plans_by_status['Assigned'].map(&:id)).with_mi_attempt
        if ! assigned_plans_with_mis.blank?
          interested.each do |mi_plan|
            mi_plan.mi_plan_status = declined_due_to_mi_attempt_status
            mi_plan.save!
          end
        else
          interested.each do |mi_plan|
            mi_plan.mi_plan_status = declined_due_to_conflict_status
            mi_plan.save!
          end
        end
      elsif ! mi_plans_by_status['Conflict'].blank? or interested.size != 1
        interested.each do |mi_plan|
          mi_plan.mi_plan_status = conflict_status
          mi_plan.save!
        end
      else
        interested.first.mi_plan_status = MiPlanStatus.find_by_name!('Assigned')
        interested.first.save!
      end
    end
  end

  def self.all_grouped_by_mgi_accession_id_then_by_status_name
    mi_plans = self.all.group_by {|i| i.gene.mgi_accession_id}
    mi_plans = mi_plans.each do |mgi_accession_id, all_for_gene|
      mi_plans[mgi_accession_id] = all_for_gene.group_by {|i| i.mi_plan_status.name}
    end
    return mi_plans
  end
end

# == Schema Information
# Schema version: 20110802094958
#
# Table name: mi_plans
#
#  id                   :integer         not null, primary key
#  gene_id              :integer         not null
#  consortium_id        :integer         not null
#  mi_plan_status_id    :integer         not null
#  mi_plan_priority_id  :integer         not null
#  production_centre_id :integer
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id) UNIQUE
#


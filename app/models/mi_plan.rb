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
    ids = MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.with_mi_attempt' when there are no mi_attempts" if ids.empty?
    where('mi_plans.id in (?)',ids)
  end

  def self.without_mi_attempt
    ids = MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.without_mi_attempt' when there are no mi_attempts" if ids.empty?
    where('mi_plans.id not in (?)',ids)
  end

  def self.with_active_mi_attempt
    ids = MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.with_active_mi_attempt' when there are no active mi_attempts" if ids.empty?
    where('mi_plans.id in (?)',ids)
  end

  def self.without_active_mi_attempt
    ids = MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.without_active_mi_attempt' when there are no active mi_attempts" if ids.empty?
    where('mi_plans.id not in (?)',ids)
  end

  def self.with_genotype_confirmed_mouse
    where('mi_plans.id in (?)', MiAttempt.genotype_confirmed.select('distinct(mi_plan_id)').map(&:mi_plan_id))
  end

  def self.assign_genes_and_mark_conflicts
    conflict_status                   = MiPlanStatus.find_by_name!('Conflict')
    declined_due_to_conflict_status   = MiPlanStatus.find_by_name!('Declined - Conflict')
    declined_due_to_mi_attempt_status = MiPlanStatus.find_by_name!('Declined - MI Attempt')
    declined_due_to_glt_mouse_status  = MiPlanStatus.find_by_name!('Declined - GLT Mouse')

    self.all_grouped_by_mgi_accession_id_then_by_status_name.each do |mgi_accession_id, mi_plans_by_status|
      interested = mi_plans_by_status['Interest']

      next if interested.blank?

      if ! mi_plans_by_status['Assigned'].blank?
        assigned_plans_with_mis      = MiPlan.where('mi_plans.id in (?)', mi_plans_by_status['Assigned'].map(&:id)).with_active_mi_attempt
        assigned_plans_with_glt_mice = MiPlan.where('mi_plans.id in (?)', mi_plans_by_status['Assigned'].map(&:id)).with_genotype_confirmed_mouse

        if ! assigned_plans_with_mis.blank? or ! assigned_plans_with_glt_mice.blank?
          if ! assigned_plans_with_glt_mice.blank?
            interested.each do |mi_plan|
              mi_plan.mi_plan_status = declined_due_to_glt_mouse_status
              mi_plan.save!
            end
          else
            interested.each do |mi_plan|
              mi_plan.mi_plan_status = declined_due_to_mi_attempt_status
              mi_plan.save!
            end
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

  def reason_for_decline_conflict
    reason_string = case self.mi_plan_status.name
    when 'Declined - GLT Mouse'
      other_centres_consortia = MiPlan.scoped
        .where('mi_plans.gene_id = :gene_id AND mi_plans.id != :id',{ :gene_id => self.gene_id, :id => self.id })
        .with_genotype_confirmed_mouse
        .map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq
      "GLT mouse produced at: #{other_centres_consortia.join(', ')}"
    when 'Declined - MI Attempt'
      other_centres_consortia = MiPlan.scoped
        .where('gene_id = :gene_id AND id != :id',{ :gene_id => self.gene_id, :id => self.id })
        .with_active_mi_attempt
        .map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq
      "MI already in progress at: #{other_centres_consortia.join(', ')}"
    when 'Declined - Conflict'
      other_consortia = MiPlan
        .where('gene_id = :gene_id AND id != :id',{ :gene_id => self.gene_id, :id => self.id })
        .where('mi_plan_status_id = ?', MiPlanStatus.find_by_name!('Assigned').id )
        .without_active_mi_attempt
        .map{ |p| p.consortium.name }.uniq
      "Other 'Assigned' MI plans for: #{other_consortia.join(', ')}"
    when 'Conflict'
      other_consortia = MiPlan
        .where('gene_id = :gene_id AND id != :id',{ :gene_id => self.gene_id, :id => self.id })
        .where('mi_plan_status_id = ?', MiPlanStatus.find_by_name!('Conflict').id )
        .without_active_mi_attempt
        .map{ |p| p.consortium.name }.uniq
      "Other MI plans for: #{other_consortia.join(', ')}"
    else
      nil
    end
    return reason_string
  end
end

# == Schema Information
# Schema version: 20110921000001
#
# Table name: mi_plans
#
#  id                   :integer         not null, primary key
#  gene_id              :integer         not null
#  consortium_id        :integer         not null
#  mi_plan_priority_id  :integer         not null
#  production_centre_id :integer
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id) UNIQUE
#


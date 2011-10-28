# encoding: utf-8

class MiPlan < ActiveRecord::Base
  INTERFACE_ATTRIBUTES = [
    'marker_symbol',
    'consortium_name',
    'production_centre_name',
    'priority',
    'number_of_es_cells_starting_qc'
  ]
  attr_accessible(*INTERFACE_ATTRIBUTES)

  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiPlan::StatusChanger

  belongs_to :gene
  belongs_to :consortium
  belongs_to :mi_plan_status
  belongs_to :mi_plan_priority
  belongs_to :production_centre, :class_name => 'Centre'
  has_many :mi_attempts
  has_many :status_stamps, :order => "#{MiPlan::StatusStamp.table_name}.created_at ASC"

  access_association_by_attribute :gene, :marker_symbol, :full_alias => :marker_symbol
  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name
  access_association_by_attribute :mi_plan_priority, :name, :full_alias => :priority
  access_association_by_attribute :mi_plan_status, :name, :full_alias => :status

  validates :marker_symbol, :presence => true
  validates :consortium_name, :presence => true
  validates :production_centre_name, :presence => {:on => :update, :if => proc {|p| p.changed.include?('production_centre_id')}}
  validates :priority, :presence => true
  validates :gene_id, :uniqueness => {:scope => [:consortium_id, :production_centre_id]}
  validates :number_of_es_cells_starting_qc, :presence => {
    :on => :update,
    :if => proc {|p| p.changed.include?('number_of_es_cells_starting_qc')},
    :message => 'cannot be unset after being set'
  }

  # BEGIN Callbacks

  before_validation :set_default_mi_plan_status
  before_validation :change_status

  before_save :record_if_status_was_changed

  after_save :create_status_stamp_if_status_was_changed

  private

  def set_default_mi_plan_status
    self.mi_plan_status ||= MiPlanStatus['Interest']
  end

  public

  def record_if_status_was_changed
    if self.changed.include? 'mi_plan_status_id'
      @new_mi_plan_status = self.mi_plan_status
    else
      @new_mi_plan_status = nil
    end
  end

  def create_status_stamp_if_status_was_changed
    if @new_mi_plan_status
      add_status_stamp @new_mi_plan_status
    end
  end

  # END Callbacks

  def add_status_stamp(status)
    self.status_stamps.create!(:mi_plan_status => status)
  end
  private :add_status_stamp

  def self.with_mi_attempt
    ids = MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.with_mi_attempt' when there are no mi_attempts" if ids.empty?
    where("#{self.table_name}.id in (?)",ids)
  end

  def self.without_mi_attempt
    ids = MiAttempt.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.without_mi_attempt' when there are no mi_attempts" if ids.empty?
    where("#{self.table_name}.id not in (?)",ids)
  end

  def self.with_active_mi_attempt
    ids = MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.with_active_mi_attempt' when there are no active mi_attempts" if ids.empty?
    where("#{self.table_name}.id in (?)",ids)
  end

  def self.without_active_mi_attempt
    ids = MiAttempt.active.select('distinct(mi_plan_id)').map(&:mi_plan_id)
    raise "Cannot run 'mi_plan.without_active_mi_attempt' when there are no active mi_attempts" if ids.empty?
    where("#{self.table_name}.id not in (?)",ids)
  end

  def self.with_genotype_confirmed_mouse
    where("#{self.table_name}.id in (?)", MiAttempt.genotype_confirmed.select('distinct(mi_plan_id)').map(&:mi_plan_id))
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
        assigned_mi_plan = interested.first
        assigned_mi_plan.mi_plan_status = MiPlanStatus[:Assigned]
        assigned_mi_plan.save!
      end
    end
  end

  def self.mark_old_plans_as_inactive
    self.where( :mi_plan_status_id => MiPlanStatus['Assigned'].id ).with_mi_attempt.each do |mi_plan|
      all_inactive, all_over_six_months_old = true, true

      mi_plan.mi_attempts.each do |mi_attempt|
        if mi_attempt.mi_attempt_status != MiAttemptStatus.micro_injection_aborted or mi_attempt.is_active == true
          all_inactive = false
        end

        if 6.months.ago < mi_attempt.mi_date.to_time_in_current_zone
          all_over_six_months_old = false
        end
      end

      if all_inactive && all_over_six_months_old
        mi_plan.mi_plan_status = MiPlanStatus['Inactive']
        mi_plan.save!
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

  def as_json(options = {})
    options.symbolize_keys!

    options[:methods] = INTERFACE_ATTRIBUTES + ['status']
    options[:only] = ['id'] + options[:methods]
    return super(options)
  end

  def self.check_for_upgradeable(params)
    params = params.symbolize_keys
    return self.search(:gene_marker_symbol_eq => params[:marker_symbol],
      :consortium_name_eq => params[:consortium_name],
      :production_centre_null => true).result.first
  end
end

# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer         not null, primary key
#  gene_id                        :integer         not null
#  consortium_id                  :integer         not null
#  mi_plan_status_id              :integer         not null
#  mi_plan_priority_id            :integer         not null
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id) UNIQUE
#


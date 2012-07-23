# encoding: utf-8

class MiPlan < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiPlan::StatusChanger

  belongs_to :sub_project
  belongs_to :gene
  belongs_to :consortium
  belongs_to :status
  belongs_to :priority
  belongs_to :production_centre, :class_name => 'Centre'
  has_many :mi_attempts
  has_many :status_stamps, :order => "#{MiPlan::StatusStamp.table_name}.created_at ASC",
          :dependent => :destroy
  has_many :phenotype_attempts

  validate do |plan|
    if plan.is_active == false
      plan.mi_attempts.each do |mi_attempt|
        if mi_attempt.is_active?
          plan.errors.add :is_active, "cannot be set to false as active micro-injection attempt '#{mi_attempt.colony_name}' is associated with this plan"
        end
      end
    end
  end

  validate do |plan|
    if plan.is_active == false
      plan.phenotype_attempts.each do |phenotype_attempt|
        if phenotype_attempt.is_active?
          plan.errors.add :is_active, "cannot be set to false as active phenotype attempt '#{phenotype_attempt.colony_name}' is associated with this plan"
        end
      end
    end
  end

  validate do |plan|
    statuses = MiPlan::Status.pre_assigned
    if statuses.include?(plan.status.name) and plan.phenotype_attempts.length != 0
      plan.errors.add(:status, 'cannot be changed - phenotype attempts exist')
    end
  end

  validate do |plan|
    not_allowed_statuses = ["Interest", "Conflict", "Inspect - GLT Mouse", "Inspect - MI Attempt", "Inspect - Conflict", "Aborted - ES Cell QC Failed", "Withdrawn"]
    if not_allowed_statuses.include?(plan.status.name) and plan.mi_attempts.length != 0
      plan.errors.add(:status, 'cannot be changed - microinjection attempts exist')
    end
  end

  validate do |plan|
    other_ids = MiPlan.where(:gene_id => plan.gene_id,
      :consortium_id => plan.consortium_id,
      :production_centre_id => plan.production_centre_id,
      :sub_project_id => plan.sub_project_id).map(&:id)
    other_ids -= [plan.id]
    if(other_ids.count != 0)
      plan.errors.add(:gene, 'already has a plan by that consortium/production centre')
    end
  end

  # BEGIN Callbacks

  before_validation :set_default_mi_plan_status
  before_validation :set_default_number_of_es_cells_starting_qc
  before_validation :set_default_sub_project
  before_validation :change_status

  before_save :major_conflict_resolution_immediate
  before_save :record_if_status_was_changed
  after_save :create_status_stamp_if_status_was_changed

  private

  def set_default_mi_plan_status
    self.status ||= MiPlan::Status['Interest']
  end

  def set_default_number_of_es_cells_starting_qc
    if number_of_es_cells_starting_qc.nil?
      self.number_of_es_cells_starting_qc = number_of_es_cells_passing_qc
    end
  end

  def set_default_sub_project
    if self.consortium && self.consortium.name == 'MGP'
      self.sub_project ||= SubProject.find_by_name!('MGPinterest')
    else
      self.sub_project ||= SubProject.find_by_name!('')
    end
  end

  def record_if_status_was_changed
    if self.changed.include? 'status_id'
      @new_mi_plan_status = self.status
    else
      @new_mi_plan_status = nil
    end
  end

  def create_status_stamp_if_status_was_changed
    if @new_mi_plan_status
      add_status_stamp @new_mi_plan_status
    end
  end

  public

  # END Callbacks

  delegate :marker_symbol, :to => :gene

  def latest_relevant_mi_attempt
    @@status_sort_order ||= {
      MiAttemptStatus.micro_injection_aborted => 1,
      MiAttemptStatus.micro_injection_in_progress => 2,
      MiAttemptStatus.chimeras_obtained => 3,
      MiAttemptStatus.genotype_confirmed => 4
    }
    ordered_mis = mi_attempts.all.sort do |mi1, mi2|
      [@@status_sort_order[mi1.mi_attempt_status], mi1.in_progress_date] <=>
              [@@status_sort_order[mi2.mi_attempt_status], mi2.in_progress_date]
    end
    if ordered_mis.empty?
      return nil
    else
      return ordered_mis.last
    end
  end

  def latest_relevant_phenotype_attempt
    return phenotype_attempts.order('is_active desc, created_at desc').first
  end

  def add_status_stamp(status_to_add)
    self.status_stamps.create!(:status => status_to_add)
  end
  private :add_status_stamp

  def reportable_statuses_with_latest_dates
    retval = {}
    status_stamps.each do |status_stamp|
      status_stamp_date = status_stamp.created_at.utc.to_date
      if !retval[status_stamp.name] or
                status_stamp_date > retval[status_stamp.name]
        retval[status_stamp.name] = status_stamp_date
      end
    end

    return retval
  end

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
    return [] if ids.empty?
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

  def self.major_conflict_resolution
    conflict_status                   = MiPlan::Status.find_by_name!('Conflict')
    inspect_due_to_conflict_status   = MiPlan::Status.find_by_name!('Inspect - Conflict')
    inspect_due_to_mi_attempt_status = MiPlan::Status.find_by_name!('Inspect - MI Attempt')
    inspect_due_to_glt_mouse_status  = MiPlan::Status.find_by_name!('Inspect - GLT Mouse')

    self.all_grouped_by_mgi_accession_id_then_by_status_name.each do |mgi_accession_id, mi_plans_by_status|
      interested = mi_plans_by_status['Interest']

      assigned = []
      MiPlan::Status.all_assigned.each do |assigned_status|
        assigned += mi_plans_by_status[assigned_status.name].to_a
      end

      next if interested.blank?

      if ! assigned.blank?
        assigned_plans_with_mis      = MiPlan.where('mi_plans.id in (?)', assigned.map(&:id)).with_active_mi_attempt
        assigned_plans_with_glt_mice = MiPlan.where('mi_plans.id in (?)', assigned.map(&:id)).with_genotype_confirmed_mouse

        if ! assigned_plans_with_glt_mice.blank?
          interested.each do |mi_plan|
            mi_plan.status = inspect_due_to_glt_mouse_status
            mi_plan.save!
          end
        elsif ! assigned_plans_with_mis.blank?
          interested.each do |mi_plan|
            mi_plan.status = inspect_due_to_mi_attempt_status
            mi_plan.save!
          end
        else
          interested.each do |mi_plan|
            mi_plan.status = inspect_due_to_conflict_status
            mi_plan.save!
          end
        end

      elsif ! mi_plans_by_status['Conflict'].blank? or interested.size != 1
        interested.each do |mi_plan|
          mi_plan.status = conflict_status
          mi_plan.save!
        end
      else
        assigned_mi_plan = interested.first
        assigned_mi_plan.status = MiPlan::Status[:Assigned]
        assigned_mi_plan.save!
      end
    end
  end

  def self.minor_conflict_resolution
    statuses = MiPlan::Status.all_affected_by_minor_conflict_resolution
    grouped_mi_plans = MiPlan.where(:status_id => statuses.map(&:id)).
            group_by(&:gene_id)
    grouped_mi_plans.each do |gene_id, mi_plans|
      assigned_mi_plans = MiPlan.where(
        :status_id => MiPlan::Status.all_assigned.map(&:id),
        :gene_id => gene_id).all
      if assigned_mi_plans.empty? and mi_plans.size == 1
        mi_plan = mi_plans.first
        mi_plan.status = MiPlan::Status['Assigned']
        mi_plan.save!
      end
    end
  end

  def self.all_grouped_by_mgi_accession_id_then_by_status_name
    mi_plans = self.all.group_by {|i| i.gene.mgi_accession_id}
    mi_plans = mi_plans.each do |mgi_accession_id, all_for_gene|
      mi_plans[mgi_accession_id] = all_for_gene.group_by {|i| i.status.name}
    end
    return mi_plans
  end

  def major_conflict_resolution_immediate
    interest_status                  = MiPlan::Status.find_by_name!('Interest')
    inactive_status                  = MiPlan::Status.find_by_name!('Inactive')
    assigned_status                  = MiPlan::Status.find_by_name!('Assigned')
    conflict_status                  = MiPlan::Status.find_by_name!('Conflict')
    inspect_due_to_conflict_status   = MiPlan::Status.find_by_name!('Inspect - Conflict')
    inspect_due_to_mi_attempt_status = MiPlan::Status.find_by_name!('Inspect - MI Attempt')
    inspect_due_to_glt_mouse_status  = MiPlan::Status.find_by_name!('Inspect - GLT Mouse')

    return if self.status != interest_status

    self.status = assigned_status

    all_grouped_by_mgi_accession_id_then_by_status_name_immediate(gene.mgi_accession_id).each do |mgi_accession_id, mi_plans_by_status|

      interested = mi_plans_by_status['Interest'] || []

      assigned = []
      MiPlan::Status.all_assigned.each do |assigned_status|
        assigned += mi_plans_by_status[assigned_status.name].to_a
      end

      if ! assigned.blank?
        assigned_plans_with_mis      = MiPlan.where('mi_plans.id in (?)', assigned.map(&:id)).with_active_mi_attempt
        assigned_plans_with_glt_mice = MiPlan.where('mi_plans.id in (?)', assigned.map(&:id)).with_genotype_confirmed_mouse

        if ! assigned_plans_with_glt_mice.blank?
          self.status = inspect_due_to_glt_mouse_status
        elsif ! assigned_plans_with_mis.blank?
          self.status = inspect_due_to_mi_attempt_status
        else
          self.status = inspect_due_to_conflict_status
        end

      elsif ! mi_plans_by_status['Conflict'].blank? or interested.size != 1
        self.status = conflict_status
      else
        self.status = assigned_status
      end
    end
  end

  def all_grouped_by_mgi_accession_id_then_by_status_name_immediate(mgi_acc_id)
    gene = Gene.find_by_mgi_accession_id!(mgi_acc_id)
    mi_plans = MiPlan.where('gene_id = ? and id != ?', gene.id, id).group_by {|i| i.gene.mgi_accession_id} if id
    mi_plans = MiPlan.where('gene_id = ?', gene.id).group_by {|i| i.gene.mgi_accession_id} if ! id
    mi_plans_new = {}
    mi_plans.each do |mgi_accession_id, all_for_gene|
      mi_plans_new[mgi_accession_id] = all_for_gene.group_by {|i| i.status.name}
    end
    return mi_plans_new
  end

  def reason_for_inspect_or_conflict
    case self.status.name
    when 'Inspect - GLT Mouse'
      other_centres_consortia = MiPlan.scoped.where('mi_plans.gene_id = :gene_id AND mi_plans.id != :id',
        { :gene_id => self.gene_id, :id => self.id }).with_genotype_confirmed_mouse.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq
      return "GLT mouse produced at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - MI Attempt'
      other_centres_consortia = MiPlan.scoped.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).with_active_mi_attempt.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq
      return "MI already in progress at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status.all_assigned ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq
      return "Other 'Assigned' MI plans for: #{other_consortia.join(', ')}"
    when 'Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status[:Conflict] ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq
      return "Other MI plans for: #{other_consortia.join(', ')}"
    else
      return nil
    end
  end

  def self.check_for_upgradeable(params)
    params = params.symbolize_keys
    return self.search(:gene_marker_symbol_eq => params[:marker_symbol],
      :consortium_name_eq => params[:consortium_name],
      :production_centre_id_null => true).result.first
  end

  def assigned?
    return MiPlan::Status.all_assigned.include?(status)
  end

  def withdrawn
    return status == MiPlan::Status['Withdrawn']
  end

  alias_method(:withdrawn?, :withdrawn)

  def withdrawn=(boolarg)
    return if boolarg == withdrawn?

    if ! MiPlan::Status.all_affected_by_minor_conflict_resolution.include?(status)
      raise RuntimeError, "cannot withdraw from status #{status.name}"
    end

    if boolarg == false
      raise RuntimeError, 'withdrawal cannot be reversed'
    else
      self.status = MiPlan::Status['Withdrawn']
    end
  end

  def distinct_old_genotype_confirmed_es_cells_count
    es_cells = []
    mi_attempts.genotype_confirmed.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      es_cells.push mi.es_cell.name if mip_date < 6.months.ago.to_date
    end

    return es_cells.sort.uniq.size
  end

  def distinct_old_non_genotype_confirmed_es_cells_count
    es_cells = []
    mi_attempts.search(:mi_attempt_status_id_not_eq => MiAttemptStatus.genotype_confirmed.id).result.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      es_cells.push mi.es_cell.name if mip_date < 6.months.ago.to_date
    end

    return es_cells.sort.uniq.size
  end

  def latest_relevant_status
    s = status.name

    plan_status_list = {}
    mi_dates = reportable_statuses_with_latest_dates
    mi_dates.each do |description, date|
      plan_status_list["#{description}"] = date.to_s
    end

    d = plan_status_list[s]

    mi = latest_relevant_mi_attempt

    if mi
      mi_status_list = {}
      mi_dates = mi.reportable_statuses_with_latest_dates
      mi_dates.each do |description, date|
        mi_status_list["#{description}"] = date.to_s
      end

      s = mi.mi_attempt_status.description
      d = mi_status_list[s]
    end

    pt = latest_relevant_phenotype_attempt

    if pt
      pheno_status_list = {}
      mi_dates = pt.reportable_statuses_with_latest_dates
      mi_dates.each do |description, date|
        pheno_status_list["#{description}"] = date.to_s
      end

      s = pt.status.name
      d = pheno_status_list[s]
    end

    return { :status => s, :date => d }
  end

  def relevant_status_stamp
    status_stamp = status_stamps.find_by_status_id!(status.id)

    mi = latest_relevant_mi_attempt
    if mi
      status_stamp = mi.status_stamps.find_by_mi_attempt_status_id!(mi.mi_attempt_status.id)
    end

    pa = latest_relevant_phenotype_attempt
    if pa
      status_stamp = pa.status_stamps.find_by_status_id!(pa.status.id)
    end

    retval = {}
    retval[:order_by] = status_stamp.status.order_by
    retval[:date] = status_stamp.created_at
    retval[:status] = status_stamp.status.name.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase
    retval[:stamp_type] = status_stamp.class.name
    retval[:stamp_id] = status_stamp.id
    retval[:mi_plan_id] = self.id
    retval[:mi_attempt_id] = mi ? mi.id : nil
    retval[:phenotype_attempt_id] = pa ? pa.id : nil

    return retval
  end

  def total_pipeline_efficiency_gene_count
    mi_attempts.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      next if ! mip_date
      return 1 if mip_date < 6.months.ago.to_date
    end
    return 0
  end

  def gc_pipeline_efficiency_gene_count
    mi_attempts.genotype_confirmed.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      next if ! mip_date
      return 1 if mip_date < 6.months.ago.to_date
    end
    return 0
  end

end

# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer         not null, primary key
#  gene_id                        :integer         not null
#  consortium_id                  :integer         not null
#  status_id                      :integer         not null
#  priority_id                    :integer         not null
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  sub_project_id                 :integer         not null
#  is_active                      :boolean         default(TRUE), not null
#  is_bespoke_allele              :boolean         default(FALSE), not null
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id) UNIQUE
#

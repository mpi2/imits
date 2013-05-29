# encoding: utf-8

class MiPlan < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiPlan::StatusManagement
  include ApplicationModel::HasStatuses

  belongs_to :sub_project
  belongs_to :gene
  belongs_to :consortium
  belongs_to :status
  belongs_to :priority
  belongs_to :production_centre, :class_name => 'Centre'
  belongs_to :es_qc_comment

  belongs_to :es_cells_received_from, :class_name => 'TargRep::CentrePipeline'

  has_many :mi_attempts
  has_many :status_stamps, :order => "#{MiPlan::StatusStamp.table_name}.created_at ASC",
          :dependent => :destroy
  has_many :phenotype_attempts
  has_many :es_cell_qcs, :dependent => :delete_all

  accepts_nested_attributes_for :status_stamps

  access_association_by_attribute :es_cells_received_from, :name

  protected :status=

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

    statuses = MiPlan::Status.all_non_assigned

    if statuses.include?(plan.status) and plan.phenotype_attempts.length != 0

      plan.phenotype_attempts.each do |phenotype_attempt|
        if phenotype_attempt.status.code != 'abt'
          plan.errors.add(:status, 'cannot be changed - phenotype attempts exist')
          return
        end
      end

    end

    if statuses.include?(plan.status) and plan.mi_attempts.length != 0

      plan.mi_attempts.each do |mi_attempt|
        if mi_attempt.status.code != 'abt'
          plan.errors.add(:status, 'cannot be changed - micro-injection attempts exist')
          return
        end
      end

    end

  end

  validate do |plan|
    other_ids = MiPlan.where(:gene_id => plan.gene_id,
      :consortium_id => plan.consortium_id,
      :production_centre_id => plan.production_centre_id,
      :sub_project_id => plan.sub_project_id,
      :is_bespoke_allele => plan.is_bespoke_allele,
      :is_conditional_allele => plan.is_conditional_allele,
      :is_deletion_allele => plan.is_deletion_allele,
      :is_cre_knock_in_allele => plan.is_cre_knock_in_allele,
      :is_cre_bac_allele => plan.is_cre_bac_allele,
      :conditional_tm1c => plan.conditional_tm1c,
      :phenotype_only => plan.phenotype_only).map(&:id)
    other_ids -= [plan.id]
    if(other_ids.count != 0)
      plan.errors.add(:gene, 'already has a plan by that consortium/production centre and allele discription')
    end
  end

  validate do |plan|
    if ! plan.new_record? and plan.changes.has_key?('status_id') and plan.withdrawn == true
      withdrawable_ids = MiPlan::Status.all_pre_assignment.map(&:id)
      if ! withdrawable_ids.include?(plan.changes['status_id'][0])
        plan.errors.add(:withdrawn, 'cannot be set - not currently in a withdrawable state')
      end
    end
  end

  validate do |plan|
    update_es_cell_received

    if !plan.number_of_es_cells_received.blank?
      if es_cells_received_on.blank?
        plan.errors.add(:es_cells_received_on, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end

      if es_cells_received_from_id.blank?
        plan.errors.add(:es_cells_received_from, 'cannot be blank if \'number_of_es_cells_received\' has a value')
      end
    end
  end

  # BEGIN Callbacks

  before_validation :set_default_number_of_es_cells_starting_qc
  before_validation :check_number_of_es_cells_passing_qc
  before_validation :set_default_sub_project

  before_validation :change_status
  before_validation :check_completion_note

  after_save :manage_status_stamps
  after_save :conflict_resolve_others

  after_save :reset_status_stamp_created_at

  after_destroy :conflict_resolve_others

  before_save :update_es_cell_qc
  
  before_save :update_es_cell_received

  scope :phenotype_only, where(:phenotype_only => true)

  private

  def update_es_cell_qc

    last = es_cell_qcs.last

    return if last && number_of_es_cells_starting_qc == last.number_starting_qc &&
      number_of_es_cells_passing_qc == last.number_passing_qc

    if number_of_es_cells_starting_qc_changed? || number_of_es_cells_passing_qc_changed?
      es_cell_qcs.build(
        :number_starting_qc => number_of_es_cells_starting_qc,
        :number_passing_qc => number_of_es_cells_passing_qc
      )
    end

  end

  def update_es_cell_received
    if number_of_es_cells_received.blank? && number_of_es_cells_starting_qc > 0
      return if centre_pipeline.blank?
      self.number_of_es_cells_received = number_of_es_cells_starting_qc
      self.es_cells_received_on = Date.today
      self.es_cells_received_from_name = centre_pipeline
    end
  end

  def set_default_number_of_es_cells_starting_qc
    if number_of_es_cells_starting_qc.nil?
      self.number_of_es_cells_starting_qc = number_of_es_cells_passing_qc
    end
  end

  def check_number_of_es_cells_passing_qc
    if ! number_of_es_cells_starting_qc.blank? && ! number_of_es_cells_passing_qc.blank?
      if number_of_es_cells_starting_qc < number_of_es_cells_passing_qc
        self.errors.add :number_of_es_cells_passing_qc, "passing qc exceeds starting qc"
      end
    end
  end

  def set_default_sub_project
    if self.consortium && self.consortium.name == 'MGP'
      self.sub_project ||= SubProject.find_by_name!('MGPinterest')
    else
      self.sub_project ||= SubProject.find_by_name!('')
    end
  end

  def new_qc_in_progress?
    !self.status_id_changed? &&
    self.status.name == 'Assigned - ES Cell QC In Progress' &&
    self.number_of_es_cells_starting_qc_changed?
  end

  def reset_status_stamp_created_at
    return unless new_qc_in_progress?
    status_stamp = self.status_stamps.find_by_status_id!(self.status_id)
    status_stamp.created_at = Time.now
    status_stamp.save!
  end

  public

  # END Callbacks

  delegate :marker_symbol, :to => :gene
  delegate :mgi_accession_id, :to => :gene

  def centre_pipeline
    @centre_pipeline ||= TargRep::CentrePipeline.all.find{|p| p.centres.include?(default_pipeline.name) }.try(:name)
  end

  def default_pipeline
    @default_pipeline ||= if mi_attempts.empty?
      gene.allele.first.try(:es_cells).try(:first).try(:pipeline)
    elsif phenotype_attempts.empty?
      self.phenotype_attempts.first.try(:es_cell).try(:pipeline)
    else
      self.mi_attempts.first.try(:es_cell).try(:pipeline)
    end
  end

  def latest_relevant_mi_attempt
    @@status_sort_order ||= {
      MiAttempt::Status.micro_injection_aborted => 1,
      MiAttempt::Status.micro_injection_in_progress => 2,
      MiAttempt::Status.chimeras_obtained => 3,
      MiAttempt::Status.genotype_confirmed => 4
    }
    ordered_mis = mi_attempts.all.sort do |mi1, mi2|
      [@@status_sort_order[mi1.status], mi1.in_progress_date] <=>
              [@@status_sort_order[mi2.status], mi2.in_progress_date]
    end
    if ordered_mis.empty?
      return nil
    else
      return ordered_mis.last
    end
  end

  def best_status_phenotype_attempt
    ordered_pas = phenotype_attempts.all.sort { |pa1, pa2| pa2.status.order_by <=> pa1.status.order_by }

    if ordered_pas.empty?
      return nil
    else
      return ordered_pas.first
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

  def reason_for_inspect_or_conflict
    case self.status.name
    when 'Inspect - GLT Mouse'
      other_centres_consortia = MiPlan.scoped.where('mi_plans.gene_id = :gene_id AND mi_plans.id != :id',
        { :gene_id => self.gene_id, :id => self.id }).with_genotype_confirmed_mouse.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq.sort
      return "GLT mouse produced at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - MI Attempt'
      other_centres_consortia = MiPlan.scoped.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).with_active_mi_attempt.map{ |p| "#{p.production_centre.name} (#{p.consortium.name})" }.uniq.sort
      return "MI already in progress at: #{other_centres_consortia.join(', ')}"
    when 'Inspect - Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status.all_assigned ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq.sort
      return "Other 'Assigned' MI plans for: #{other_consortia.join(', ')}"
    when 'Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status[:Conflict] ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq.sort
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

  def distinct_old_genotype_confirmed_es_cells_count
    es_cells = []
    mi_attempts.genotype_confirmed.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      es_cells.push mi.es_cell.name if mip_date < 6.months.ago.to_date && mi.es_cell
    end

    return es_cells.sort.uniq.size
  end

  def distinct_old_non_genotype_confirmed_es_cells_count
    es_cells = []
    mi_attempts.search(:status_id_not_eq => MiAttempt::Status.genotype_confirmed.id).result.each do |mi|
      dates = mi.reportable_statuses_with_latest_dates
      mip_date = dates["Micro-injection in progress"]
      es_cells.push mi.es_cell.name if mip_date < 6.months.ago.to_date && mi.es_cell
    end

    return es_cells.sort.uniq.size
  end

  def latest_relevant_status
    s = status.name

    plan_status_list = {}
    mi_dates = reportable_statuses_with_latest_dates
    mi_dates.each do |name, date|
      plan_status_list["#{name}"] = date.to_s
    end

    d = plan_status_list[s]

    mi = latest_relevant_mi_attempt

    if mi
      mi_status_list = {}
      mi_dates = mi.reportable_statuses_with_latest_dates
      mi_dates.each do |name, date|
        mi_status_list["#{name}"] = date.to_s
      end

      s = mi.status.name
      d = mi_status_list[s]
    end

    pt = latest_relevant_phenotype_attempt

    if pt
      pheno_status_list = {}
      mi_dates = pt.reportable_statuses_with_latest_dates
      mi_dates.each do |name, date|
        pheno_status_list["#{name}"] = date.to_s
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
      status_stamp = mi.status_stamps.find_by_status_id!(mi.status.id)
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

  def self.readable_name
    return 'plan'
  end

  def self.get_completion_note_enum
    ['', "Handoff complete", "Allele not needed"]
  end

  def check_completion_note
    self.completion_note = '' if self.completion_note.blank?

    if ! MiPlan.get_completion_note_enum.include?(self.completion_note)
      legal_values = MiPlan.get_completion_note_enum.map { |k| "'#{k}'" }.join(', ')
      self.errors.add :completion_note, "recognised values are #{legal_values}"
    end
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
#  is_conditional_allele          :boolean         default(FALSE), not null
#  is_deletion_allele             :boolean         default(FALSE), not null
#  is_cre_knock_in_allele         :boolean         default(FALSE), not null
#  is_cre_bac_allele              :boolean         default(FALSE), not null
#  comment                        :text
#  withdrawn                      :boolean         default(FALSE), not null
#  es_qc_comment_id               :integer
#  phenotype_only                 :boolean         default(FALSE)
#  completion_note                :string(100)
#  recovery                       :boolean
#  conditional_tm1c               :boolean         default(FALSE), not null
#  ignore_available_mice          :boolean         default(FALSE), not null
#  number_of_es_cells_received    :integer
#  es_cells_received_on           :date
#  es_cells_received_from_id      :integer
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id,is_bespoke_allele,is_conditional_allele,is_deletion_allele,is_cre_knock_in_allele,is_cre_bac_allele,conditional_tm1c,phenotype_only) UNIQUE
#


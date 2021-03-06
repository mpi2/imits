# encoding: utf-8

class MiPlan < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiPlan::StatusManagement

## Constants
  FUNDING = {'IMPC' => {
                 'HMGU' => ['Helmholtz GMC'],
                 'ICS' => ['Phenomin', 'Helmholtz GMC'],
                 'Harwell' => ['BaSH', 'MRC'],
                 'UCD' =>['DTCC'],
                 'WTSI' =>['MGP', 'BaSH'],
                 'Monterotondo' =>['Monterotondo'],
                 'BCM' => 'all',
                 'TCP' => 'all',
                 'JAX' => 'all',
                 'RIKEN BRC' => 'all'
                },
            'KOMP' => [
                'BaSH',
                'DTCC',
                'JAX'
               ]
           }

## Associations
  belongs_to :gene
  belongs_to :consortium
  belongs_to :production_centre, :class_name => 'Centre'
  belongs_to :status
  belongs_to :priority
  belongs_to :sub_project
  belongs_to :es_qc_comment

  belongs_to :es_cells_received_from, :class_name => 'TargRep::CentrePipeline'

  has_many :mi_attempts
  has_many :status_stamps, :order => "#{MiPlan::StatusStamp.table_name}.created_at ASC",
          :dependent => :destroy
  has_many :mouse_allele_mods
  has_many :phenotyping_productions
  has_many :es_cell_qcs, :dependent => :delete_all


## Nested Attributes
  accepts_nested_attributes_for :status_stamps

## access_associations
  access_association_by_attribute :es_cells_received_from, :name
  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name

## Delegates
  delegate :marker_symbol, :to => :gene
  delegate :mgi_accession_id, :to => :gene

## Scopes
  scope :phenotype_only, where(:phenotype_only => true)
  scope :es_cell_qc_only, where(:es_cell_qc_only => true)
  scope :planned_injection, where(:phenotype_only => false, :es_cell_qc_only => false)
  scope :with_mi_attempt, -> { planned_injection.joins(:mi_attempts).uniq }
  scope :without_mi_attempt, -> { planned_injection.joins("LEFT JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id").where("mi_attempts.id IS NULL").uniq }
  scope :with_active_mi_attempt, -> { planned_injection.joins(:mi_attempts).where("mi_attempts.is_active = true").uniq }
  scope :without_active_mi_attempt, -> { planned_injection.joins("LEFT JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id AND mi_attempts.is_active = true").where("mi_attempts.id IS NULL").uniq }
  scope :with_genotype_confirmed_mouse, -> { planned_injection.joins(:mi_attempts).where("mi_attempts.status_id = #{MiAttempt::Status.genotype_confirmed.id}").uniq }

  protected :status=

##Callbacks
  before_validation :set_default_number_of_es_cells_starting_qc
  before_validation :check_number_of_es_cells_passing_qc
  before_validation :set_default_sub_project
  before_validation :change_status
  before_validation :check_completion_note

  before_save :update_es_cell_qc
  before_save :update_es_cell_received

  after_save :manage_status_stamps
  after_save :conflict_resolve_others
  after_save :reset_status_stamp_created_at

  after_destroy :conflict_resolve_others


##Validations
  ## Validation Blocks
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
    conflict_statuses = MiPlan::Status.all_pre_assignment

    if statuses.include?(plan.status) and plan.phenotype_attempts.length != 0

      plan.phenotype_attempts.each do |phenotype_attempt|
        if phenotype_attempt.status_name != 'Phenotype Attempt Aborted' and !conflict_statuses.include?(plan.status)
          plan.errors.add(:status, 'cannot be changed - phenotype attempts exist')
          return
        end
      end

    end

    if statuses.include?(plan.status) and plan.mi_attempts.length != 0

      plan.mi_attempts.each do |mi_attempt|
        if mi_attempt.status.code != 'abt' and !conflict_statuses.include?(plan.status)
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
      :point_mutation => plan.point_mutation,
      :conditional_point_mutation => plan.conditional_point_mutation,
      :mutagenesis_via_crispr_cas9 => plan.mutagenesis_via_crispr_cas9,
      :phenotype_only => plan.phenotype_only,
      :es_cell_qc_only => plan.es_cell_qc_only).map(&:id)
    other_ids -= [plan.id]
    if(other_ids.count != 0)
      plan.errors.add(:gene, 'already has a plan by that consortium/production centre and allele discription')
    end
  end

  validate do |plan|
    # if we want to set the withdrawn state, do further checks
    if ( self.withdrawn == true )
      unless plan.can_be_withdrawn?
        plan.errors.add(:withdrawn, 'cannot be set - plan is not currently in a withdrawable state')
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

  validate do |plan|
    if !plan.completion_comment.blank? and plan.completion_note.blank?
      plan.errors.add(:completion_note, 'cannot be blank if a Completion Comment has been added')
    end
  end

  validate do |plan|
    if plan.phenotype_only == true and plan.es_cell_qc_only == true
      plan.errors.add(:phenotype_only, 'cannot be set to true when es_cell_qc_only is also set to true')
      plan.errors.add(:es_cell_qc_only, 'cannot be set to true when phenotype_only is also set to true')
    end
  end

## Validation Methods
  def check_number_of_es_cells_passing_qc
    if ! number_of_es_cells_starting_qc.blank? && ! number_of_es_cells_passing_qc.blank?
      if number_of_es_cells_starting_qc < number_of_es_cells_passing_qc
        self.errors.add :number_of_es_cells_passing_qc, "passing qc exceeds starting qc"
      end
    end
  end

  def check_completion_note
    self.completion_note = '' if self.completion_note.blank?

    if ! MiPlan.get_completion_note_enum.include?(self.completion_note)
      legal_values = MiPlan.get_completion_note_enum.map { |k| "'#{k}'" }.join(', ')
      self.errors.add :completion_note, "recognised values are #{legal_values}"
    end
  end

## Callback Methods
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

  def reset_status_stamp_created_at
    return unless new_qc_in_progress?
    status_stamp = self.status_stamps.find_by_status_id!(self.status_id)
    status_stamp.created_at = Time.now
    status_stamp.save!
  end

  def update_es_cell_received
    if number_of_es_cells_received.blank? && number_of_es_cells_starting_qc.to_i > 0
      return if centre_pipeline.blank?
      return if es_cell_qc_in_progress_date.blank?
      self.number_of_es_cells_received = number_of_es_cells_starting_qc
      self.es_cells_received_on = es_cell_qc_in_progress_date
      self.es_cells_received_from_name = centre_pipeline
    end
  end

# Private Instance Methods
  def add_status_stamp(status_to_add)
    self.status_stamps.create!(:status => status_to_add)
  end
  private :add_status_stamp


# Instance Methods
  def new_qc_in_progress?
    !self.status_id_changed? &&
    self.status.name == 'Assigned - ES Cell QC In Progress' &&
    self.number_of_es_cells_starting_qc_changed?
  end

  def assigned?
    return MiPlan::Status.all_assigned.include?(status) && es_cell_qc_only == false
  end

  # check whether the Plan can be withdrawn, for validation
  def can_be_withdrawn?

    return true if ( self.new_record? )
    return true if ( self.mi_attempts.count == 0 && self.phenotype_attempts.count == 0 ) # self.assigned? && 

    withdrawable_ids = MiPlan::Status.all_pre_assignment.map(&:id) << MiPlan::Status.find_by_name('Withdrawn').id

    if ( self.changes.has_key?('status_id') )
      return true if ( withdrawable_ids.include?(self.changes['status_id'][0]) )
    else
      return true if ( withdrawable_ids.include?(self.status_id) )
    end
    
    return false
  end


  def impc_activity?
    return false if self.production_centre.blank? || self.consortium.blank?

    if !FUNDING['IMPC'][self.production_centre.name].blank? && (FUNDING['IMPC'][self.production_centre.name] == 'all' || FUNDING['IMPC'][self.production_centre.name].include?(self.consortium.name))
      return true
    else
      return false
    end
  end

  def komp_activity?
    return false if self.consortium.blank? || !FUNDING['KOMP'].include?(self.consortium.name)
    return true
  end

  def centre_pipeline
    @centre_pipeline ||= TargRep::CentrePipeline.all.find{|p| p.centres.include?(default_pipeline.try(:name)) }.try(:name)
  end

  def default_pipeline
    @default_pipeline ||= self.mi_attempts.first.try(:es_cell).try(:pipeline)
  end

  def products
   @products ||= {:mi_attempts => mi_attempts.where("is_active = true"), :phenotype_attempts => phenotype_attempts.reject{|pa| !pa.is_active}}
  end

  def phenotype_attempts
    pas = []
    phenotype_attempt_ids = []
    phenotype_attempt_ids << mouse_allele_mods.map{|mam| mam.phenotype_attempt_id}.reject { |c| c.blank? }
    phenotype_attempt_ids << phenotyping_productions.map{|pp| pp.phenotype_attempt_id}.reject { |c| c.blank? }

    pas = phenotype_attempt_ids.flatten.uniq.reject { |c| c.blank? }.map{ |pa_id| Public::PhenotypeAttempt.find(pa_id)}
    return pas
  end

  def es_cell_qc_in_progress_date
    status_stamp = self.status_stamps.where(status_id: MiPlan::Status['Assigned - ES Cell QC In Progress'].id).first
    status_stamp.created_at.to_date if status_stamp
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
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status.all_assigned ).where(:es_cell_qc_only => false).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq.sort
      return "Other 'Assigned' MI plans for: #{other_consortia.join(', ')}"
    when 'Conflict'
      other_consortia = MiPlan.where('gene_id = :gene_id AND id != :id',
        { :gene_id => self.gene_id, :id => self.id }).where(:status_id => MiPlan::Status[:Conflict] ).without_active_mi_attempt.map{ |p| p.consortium.name }.uniq.sort
      return "Other MI plans for: #{other_consortia.join(', ')}"
    else
      return nil
    end
  end


  def latest_relevant_mi_attempt

    status_sort_order =  MiAttempt::Status.status_order

    ordered_mis = mi_attempts.all.sort do |mi1, mi2|
      [status_sort_order[mi1.public_status], mi2.in_progress_date] <=>
              [status_sort_order[mi2.public_status], mi1.in_progress_date]
    end
    if ordered_mis.empty?
      return nil
    else
      return ordered_mis.last
    end
  end

  def best_status_phenotype_attempt
    status_sort_order =  Public::PhenotypeAttempt.status_order

    ordered_pas = phenotype_attempts.sort { |pa1, pa2| status_sort_order[pa2.status_name] <=> status_sort_order[pa1.status.order_by] }

    if ordered_pas.empty?
      return nil
    else
      return ordered_pas.first
    end
  end

  def latest_relevant_phenotype_attempt

    status_sort_order =  Public::PhenotypeAttempt.status_order

    ordered_pas = phenotype_attempts.sort do |pi1, pi2|
      [status_sort_order[pi1.public_status_name], pi2.in_progress_date] <=>
              [status_sort_order[pi2.public_status_name], pi1.in_progress_date]
    end
    if ordered_pas.empty?
      return nil
    else
      return ordered_pas.last
    end
  end

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
    status_stamp = status_stamps.find_by_status_id!(status_id)

    mi = latest_relevant_mi_attempt
    if mi
      status_stamp = mi.status_stamps.find_by_status_id!(mi.public_status.id)
    end

    pa = latest_relevant_phenotype_attempt
    if pa
      status_stamp = pa.status_stamps.find_by_status_id!(pa.public_status.id)
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

  def self.check_for_upgradeable(params)
    params = params.symbolize_keys
    return self.search(:gene_marker_symbol_eq => params[:marker_symbol],
      :consortium_name_eq => params[:consortium_name],
      :production_centre_id_null => true).result.first
  end

  def self.readable_name
    return 'plan'
  end

  def self.get_completion_note_enum
    ['', "Handoff complete", "Allele not needed", "Effort concluded"]
  end

  def self.find_or_create_plan(object, params, &check_plan_exists)
    raise "Did not check to see if mi_plan already exists" if check_plan_exists.nil?

    mi_plans = check_plan_exists.call(object)
    if mi_plans.count == 1
      mi_plan = mi_plans.first
    elsif mi_plans.count == 0
      mi_plan = MiPlan.new(params)
      mi_plan.force_assignment = true
      if mi_plan.valid?
        mi_plan.save
      else
        raise "Invalid mi_plan. #{mi_plan.errors.messages}"
      end
    else
      raise "Multiple mi_plans returned. Expected 0-1 mi_plan to be returned for the given params: #{params}"
    end
    return mi_plan

  end

  def self.impc_activity_sql_where

    where_array = []
    FUNDING['IMPC'].each do |key, value|
      where_clause = "(centres.name = '#{key}' "
      if value != 'all'
        where_clause += "AND consortia.name IN ('#{value.join("', '")}')"
      end
      where_clause += ") "
      where_array << where_clause
    end
    return where_array.join(" OR ")
  end

  def self.komp_activity_sql_where
    where_array = FUNDING['KOMP']
    return "consortia.name IN ('#{where_array.join("', '")}')"
  end


end

# == Schema Information
#
# Table name: mi_plans
#
#  id                             :integer          not null, primary key
#  gene_id                        :integer          not null
#  consortium_id                  :integer          not null
#  status_id                      :integer          not null
#  priority_id                    :integer
#  production_centre_id           :integer
#  created_at                     :datetime
#  updated_at                     :datetime
#  number_of_es_cells_starting_qc :integer
#  number_of_es_cells_passing_qc  :integer
#  sub_project_id                 :integer          not null
#  is_active                      :boolean          default(TRUE), not null
#  is_bespoke_allele              :boolean          default(FALSE), not null
#  is_conditional_allele          :boolean          default(FALSE), not null
#  is_deletion_allele             :boolean          default(FALSE), not null
#  is_cre_knock_in_allele         :boolean          default(FALSE), not null
#  is_cre_bac_allele              :boolean          default(FALSE), not null
#  comment                        :text
#  withdrawn                      :boolean          default(FALSE), not null
#  es_qc_comment_id               :integer
#  phenotype_only                 :boolean          default(FALSE)
#  completion_note                :string(100)
#  recovery                       :boolean
#  conditional_tm1c               :boolean          default(FALSE), not null
#  ignore_available_mice          :boolean          default(FALSE), not null
#  number_of_es_cells_received    :integer
#  es_cells_received_on           :date
#  es_cells_received_from_id      :integer
#  point_mutation                 :boolean          default(FALSE), not null
#  conditional_point_mutation     :boolean          default(FALSE), not null
#  allele_symbol_superscript      :text
#  report_to_public               :boolean          default(TRUE), not null
#  completion_comment             :text
#  mutagenesis_via_crispr_cas9    :boolean          default(FALSE)
#  es_cell_qc_only                :boolean          default(FALSE)
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id,sub_project_id,is_bespoke_allele,is_conditional_allele,is_deletion_allele,is_cre_knock_in_allele,is_cre_bac_allele,conditional_tm1c,phenotype_only,mutagenesis_via_crispr_cas9,es_cell_qc_only) UNIQUE
#

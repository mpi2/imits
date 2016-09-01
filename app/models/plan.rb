# encoding: utf-8

class Plan < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute

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

  belongs_to :gene
  belongs_to :consortium
  belongs_to :production_centre, :class_name => 'Centre'

  # Tasks. Should always be one to many
  has_many :es_cell_qcs #there will only be one, but make the logic easier.
  def es_cell_qc #has_one es_cell_qc
    return nil if es_cell_qcs.blank?
    return es_cell_qcs.first
  end
  has_many :mi_attempts
  has_many :mouse_allele_mods
  has_many :phenotyping_productions
  def phenotype_attempts #has_many phenotype_attempts
    pas = []
    phenotype_attempt_ids = []
    phenotype_attempt_ids << mouse_allele_mods.map{|mam| mam.phenotype_attempt_id}.reject { |c| c.blank? }
    phenotype_attempt_ids << phenotyping_productions.map{|pp| pp.phenotype_attempt_id}.reject { |c| c.blank? }

    pas = phenotype_attempt_ids.flatten.uniq.reject { |c| c.blank? }.map{ |pa_id| Public::PhenotypeAttempt.find(pa_id)}
    return pas
  end
  has_many :crispr_mi_attempts, :class_name => 'MiAttempt', :conditions => "mi_attempts.es_cell_id IS NULL"
  has_many :es_cell_mi_attempts, :class_name => 'MiAttempt', :conditions => "mi_attempts.es_cell_id IS NOT NULL"

  has_many :plan_intentions, :class_name => 'PlanIntention', :order => 'intention_id'

  has_one :qc_es_cell_intention, :class_name => 'PlanIntention', :conditions => {:intention_id => 1}
  has_one :micro_injected_es_cell_intention, :class_name => 'PlanIntention', :conditions => {:intention_id => 2}
  has_one :micro_injected_nuclease_intention, :class_name => 'PlanIntention', :conditions => {:intention_id => 3}
  has_one :modify_mice_allele_intention, :class_name => 'PlanIntention', :conditions => {:intention_id => 4}
  has_one :phenotype_mice_intention, :class_name => 'PlanIntention', :conditions => {:intention_id => 5}

# Used by Plan Grid filters. Select Intentions which have not been withdrawn.
  has_one :qcesci_not_withdrawn, :class_name => 'PlanIntention', :conditions => {:intention_id => 1, :withdrawn => false}
  has_one :miesci_not_withdrawn, :class_name => 'PlanIntention', :conditions => {:intention_id => 2, :withdrawn => false}
  has_one :mini_not_withdrawn, :class_name => 'PlanIntention', :conditions => {:intention_id => 3, :withdrawn => false}
  has_one :mmai_not_withdrawn, :class_name => 'PlanIntention', :conditions => {:intention_id => 4, :withdrawn => false}
  has_one :pmi_not_withdrawn, :class_name => 'PlanIntention', :conditions => {:intention_id => 5, :withdrawn => false}


  access_association_by_attribute :consortium, :name
  access_association_by_attribute :production_centre, :name
  access_association_by_attribute :gene, :marker_symbol, :full_alias => 'marker_symbol'

#  delegate :marker_symbol, :to => :gene
  delegate :mgi_accession_id, :to => :gene
  
# BEGIN Callbacks
  #before_validation

  ## VALIDATION
  validates :gene, :presence => true

  validate do |plan|
    other_ids = Plan.where(:gene_id => plan.gene_id,
      :consortium_id => plan.consortium_id,
      :production_centre_id => plan.production_centre_id).map(&:id)
    other_ids -= [plan.id]
    if(other_ids.count != 0)
      plan.errors.add(:gene, 'already has a plan by that consortium/production centre')
    end
  end


  ## Instance Methods
  def products
   @products ||= {:mi_attempts => mi_attempts.where("is_active = true"), :phenotype_attempts => phenotype_attempts.reject{|pa| !pa.is_active}}
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



  # def self.with_mi_attempt
  #   ids = MiAttempt.select('distinct(plan_id)').map(&:plan_id)
  #   raise "Cannot run 'plan.with_mi_attempt' when there are no mi_attempts" if ids.empty?
  #   where("#{self.table_name}.id in (?)",ids)
  # end

  # def self.without_mi_attempt
  #   ids = MiAttempt.select('distinct(plan_id)').map(&:plan_id)
  #   raise "Cannot run 'plan.without_mi_attempt' when there are no mi_attempts" if ids.empty?
  #   where("#{self.table_name}.id not in (?)",ids)
  # end

  # def self.with_active_mi_attempt
  #   ids = MiAttempt.active.select('distinct(plan_id)').map(&:plan_id)
  #   return [] if ids.empty?
  #   where("#{self.table_name}.id in (?)",ids)
  # end

  # def self.without_active_mi_attempt
  #   ids = MiAttempt.active.select('distinct(plan_id)').map(&:plan_id)
  #   raise "Cannot run 'plan.without_active_mi_attempt' when there are no active mi_attempts" if ids.empty?
  #   where("#{self.table_name}.id not in (?)",ids)
  # end

  # def self.with_genotype_confirmed_mouse
  #   where("#{self.table_name}.id in (?)", MiAttempt.genotype_confirmed.select('distinct(plan_id)').map(&:plan_id))
  # end

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

  # def self.check_for_upgradeable(params)
  #   params = params.symbolize_keys
  #   return self.search(:gene_marker_symbol_eq => params[:marker_symbol],
  #     :consortium_name_eq => params[:consortium_name],
  #     :production_centre_id_null => true).result.first
  # end

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
    ['', "Handoff complete", "Allele not needed", "Effort concluded"]
  end

  def check_completion_note
    self.completion_note = '' if self.completion_note.blank?

    if ! Plan.get_completion_note_enum.include?(self.completion_note)
      legal_values = Plan.get_completion_note_enum.map { |k| "'#{k}'" }.join(', ')
      self.errors.add :completion_note, "recognised values are #{legal_values}"
    end
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
# Table name: plans
#
#  id                   :integer          not null, primary key
#  gene_id              :integer          not null
#  consortium_id        :integer
#  production_centre_id :integer
#

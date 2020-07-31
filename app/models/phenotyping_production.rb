# encoding: utf-8

class PhenotypingProduction < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include PhenotypingProduction::StatusManagement
  include PhenotypingProduction::LateAdultStatusManagement
  include ApplicationModel::BelongsToMiPlan
  include ApplicationModel::BelongsToMiPlan::Public

  belongs_to :mi_plan
  belongs_to :parent_colony, :class_name => 'Colony'
  belongs_to :status
  belongs_to :late_adult_status
  belongs_to :colony_background_strain, :class_name => 'Strain'

  has_many   :status_stamps, :order => "#{PhenotypingProduction::StatusStamp.table_name}.created_at ASC", dependent: :destroy
  has_many   :late_adult_status_stamps, :order => "#{PhenotypingProduction::LateAdultStatusStamp.table_name}.created_at ASC", dependent: :destroy
  has_many   :tissue_distribution_centres, dependent: :destroy

  access_association_by_attribute :colony_background_strain, :name

  accepts_nested_attributes_for :status_stamps
  accepts_nested_attributes_for :late_adult_status_stamps
  accepts_nested_attributes_for :tissue_distribution_centres, :allow_destroy => true
  
  protected :status=
  protected :late_adult_status=

  before_validation :allow_override_of_plan
  before_validation :check_and_set_cohort_centre
  before_validation :change_status
  before_validation :late_adult_change_status

  before_save :set_colony_background_strain
  before_save :set_phenotyping_experiments_started_if_blank
  before_save :set_late_adult_phenotyping_experiments_started_if_blank
  before_save :set_phenotype_attempt_id
  after_save :manage_status_stamps
  after_save :late_adult_manage_status_stamps

## BEFORE VALIDATION METHODS
  before_validation do |pp|
    if ! pp.colony_name.nil?
      pp.colony_name = pp.colony_name.to_s.strip || pp.colony_name
      pp.colony_name = pp.colony_name.to_s.gsub(/\s+/, ' ')
    end
  end

  def allow_override_of_plan
    return if self.consortium_name.blank? or self.phenotyping_centre_name.blank? or self.gene.blank?
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.phenotyping_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.try(:parent_colony).try(:mi_plan)
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.phenotyping_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.phenotyping_centre_name}' AND phenotype_only = true")
      end
    end
    self.mi_plan = set_plan
  end

  def check_and_set_cohort_centre
    return if @cohort_production_centre_name.nil?
    if @cohort_production_centre_name.blank?
      self.cohort_production_centre_id = nil
    else
      centre = Centre.find_by_name(@cohort_production_centre_name)
      if !centre.blank?
        if centre.name == phenotyping_centre_name && centre.name != production_centre_name
          self.rederivation_started = true
          self.rederivation_complete = true
          self.cohort_production_centre_id = nil
        elsif centre.name == production_centre_name && self.rederivation_started == false
          self.cohort_production_centre_id = nil
        elsif self.rederivation_started == false
          self.cohort_production_centre_id = centre.id
        end
      else
        self.error.add(:cohort_production_centre_name, 'invalid centre name')
        return
      end
    end

    if !self.cohort_production_centre_id.blank? && Centre.find(self.cohort_production_centre_id).name != phenotyping_centre_name
      self.rederivation_started = false
      self.rederivation_complete = false
    end
    return true
  end

## VALIDATION

  #mi_plan validatation
  validate do |pp|
    if pp.mi_plan.nil?
      pp.errors.add(:consortium_name, 'must be set')
      pp.errors.add(:centre_name, 'must be set')
      return
    end

    if mi_plan != parent_colony.mi_plan && mi_plan.phenotype_only == false
      pp.errors[:mi_plan] << 'must be either the same as the mouse production plan OR phenotype_only'
    end

# REMOVED VALIDATION TO ALLOW CENTERS TO RE PHENOTYPE (POTENTIALLY USING DIFFERENT CONTROLS ANIMALS).
# CAN BE RE ESTABLISHED BUT VALIDATION MUST BE IGNORED IF CONSORTIA ARE LEGACY LINES.

#    other_ids = []
#    other_ids = PhenotypingProduction.includes(:mi_plan).where("
#      mi_plans.consortium_id = #{pp.mi_plan.consortium_id} AND
#      mi_plans.production_centre_id = #{pp.mi_plan.production_centre_id} AND
#      parent_colony_id = #{pp.parent_colony_id}").map{|a| a.id} unless pp.parent_colony_id.blank?

#    other_ids -= [self.id]
#    if(other_ids.count != 0)
#      pp.errors[:already] << 'has production for this consortium & production centre'
#    end
  end

  validates :parent_colony, :presence => true
  validates :colony_name, :presence => true, :uniqueness => {:case_sensitive => false}, :allow_nil => false

  # colony_name cannot be changed once phenotype_started = true
  validate do |pp|
    if pp.changes.has_key?('colony_name') && pp.phenotyping_started == true
      pp.errors.add(:base, 'Cohort Colony name cannot be changed once data has been submitted to PhenoDCC.')
    end
  end

  # colony_background_strain cannot be changed once phenotype_started = true
  validate do |pp|
    if pp.changes.has_key?('colony_background_strain_id') && pp.phenotyping_started == true
      pp.errors.add(:base, 'Colony background strain name cannot be changed once data has been submitted to PhenoDCC.')
    end
  end

  # colony_background_strain
  validate do |pp|
    if !colony_background_strain_name.blank? && Strain.find_by_name(colony_background_strain_name).blank?
      pp.errors.add(:colony_background_strain_name, 'Invalid colony background strain name')
    end
  end

  # genotype confirmed colony
  validate do |pp|  
    if parent_colony && !(parent_colony.genotype_confirmed == true || parent_colony.mouse_allele_mod.try(:parent_colony).try(:genotype_confirmed) == true)
      pp.errors.add(:production_colony_name, "Must be 'Genotype confirmed'")
    end
  end

## BEFORE SAVE METHODS
  def set_colony_background_strain
    if colony_background_strain_name.blank?
      colony_background_strain = parent_colony.background_strain
    end
  end

  def set_phenotyping_experiments_started_if_blank
    #if phenotyping started or complete
    return unless self.phenotyping_experiments_started.blank?
    if ['pds', 'pdc'].include?(status.code)
      phenotyping_started_status_stamps = self.status_stamps.joins(:status).where("phenotyping_production_statuses.code = 'pds'")
      self.phenotyping_experiments_started = !phenotyping_started_status_stamps.blank? ? phenotyping_started_status_stamps.first.created_at : Time.now()
    end
  end
  protected :set_phenotyping_experiments_started_if_blank



  def set_late_adult_phenotyping_experiments_started_if_blank
    #if phenotyping started or complete
    return unless self.late_adult_phenotyping_experiments_started.blank?
    if ['pdlas', 'pdlac'].include?(status.code)
      late_adult_phenotyping_started_status_stamps = self.late_adult_status_stamps.joins(:status).where("phenotyping_production_statuses.code = 'pdlas'")
      self.late_adult_phenotyping_experiments_started = !late_adult_phenotyping_started_status_stamps.blank? ? late_adult_phenotyping_started_status_stamps.first.created_at : Time.now()
    end
  end
  protected :set_late_adult_phenotyping_experiments_started_if_blank

  def set_phenotype_attempt_id
    return unless phenotype_attempt_id.blank?
    if !parent_colony.mouse_allele_mod_id.blank?
      self.phenotype_attempt_id = parent_colony.mouse_allele_mod.phenotype_attempt_id
    else
      paid = PhenotypeAttemptId.new
      paid.save
      self.phenotype_attempt_id = paid.id
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?
    i = 0
    begin
      i += 1
      j = i > 0 ? "-#{i}" : ""
      new_colony_name = "#{self.parent_colony.name}_#{mi_plan.phenotyping_centre_name}#{j}"
    end until self.class.find_by_colony_name(new_colony_name).blank?
    self.colony_name = new_colony_name
  end


## METHODS

  def parent_colony_background_strain_name
    parent_colony.try(:background_strain_name)
  end

  def parent_colony_name
    return parent_colony.name unless parent_colony.blank?
    return nil
  end

  def parent_colony_name=(arg)
    set_parent_colony_name(arg)
  end

  def mi_parent_colony_name=(arg)
    set_parent_colony_name(arg, 'mi_attempt')
  end

  def mam_parent_colony_name=(arg)
    set_parent_colony_name(arg, 'mouse_allele_mod')
  end

  def set_parent_colony_name(arg, filter = nil)
    return nil if arg.blank?

    if !arg.respond_to?(:to_str)
      errors.add(:parent_colony_name, "value is invalid")
      return
    end

    if filter == 'mi_attempt'
      parent_colony_model = Colony.where("name = '#{arg}' AND mi_attempt_id IS NOT NULL")
    elsif filter == 'mouse_allele_mod'
      parent_colony_model = Colony.where("name = '#{arg}' AND mouse_allele_mod_id IS NOT NULL")
    else
      parent_colony_model = Colony.where("name = '#{arg}'")
    end

    if parent_colony_model.count == 0
      errors.add(:parent_colony_name, "#{arg} does not exist")
    end

    raise "Multiple Colonies found with the name equal to #{arg}" if parent_colony_model.length > 1

    self.parent_colony_id = parent_colony_model.first.id
    return arg
  end
  private :set_parent_colony_name


  def cohort_production_centre_name=(arg)
    if arg.blank?
      @cohort_production_centre_name = '' if arg.blank?
    else
      @cohort_production_centre_name = arg
    end
  end

  def cohort_production_centre_name
    return @cohort_production_centre_name unless @cohort_production_centre_name.blank?
    return Centre.find(cohort_production_centre_id).name unless cohort_production_centre_id.blank?
    return phenotyping_centre_name if rederivation_started == true
    return production_centre_name
  end


  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif parent_colony.try(:gene)
      return parent_colony.gene
    else
      return nil
    end
  end

  def status_name; status.try(:name); end

  def late_adult_status_name; late_adult_status.try(:name); end

  def colony_background_strain_mgi_name
    colony_background_strain.try(:mgi_strain_name)
  end

  def colony_background_strain_mgi_accession
    colony_background_strain.try(:mgi_strain_accession_id)
  end

  def mouse_allele_symbol_superscript
    return '' if parent_colony.blank?
    parent_colony.alleles.map{|a| a.mgi_allele_symbol_superscript}.join('')
  end
  
  def mouse_allele_symbol
    return '' if parent_colony.blank? || parent_colony.alleles[0].blank?
    colony_alleles = parent_colony.alleles.map{|a| a.mgi_allele_symbol_superscript}.join('')
    if !colony_alleles.blank?
      return marker_symbol + '<sup>' + colony_alleles + '</sup>'
    else
      return ''
    end
  end


  def marker_symbol
    gene.try(:marker_symbol) 
  end

  def mgi_accession_id
    gene.try(:mgi_accession_id) 
  end

  def phenotyping_consortium_name
    consortium_name
  end

  def consortium_name
    # override included method
    if @consortium_name.blank?
      mi_plan.try(:consortium).try(:name)
    else
      return @consortium_name
    end
  end

  def phenotyping_consortium_name=(arg)
    consortium_name = arg
  end

  def consortium_name=(arg)
    # override included method
    @consortium_name = arg
    if @consortium_name != self.mi_plan.try(:consortium).try(:name)
      # this forces the changed methods to record a change.
      self.changed_attributes['consortium_name'] = arg
    end
  end

  def phenotyping_centre_name
    if @phenotyping_centre_name.blank?
      mi_plan.try(:production_centre).try(:name)
    else
      return @phenotyping_centre_name
    end
  end

  def phenotyping_centre_name=(arg)
    @phenotyping_centre_name = arg
    if @phenotyping_centre_name != self.mi_plan.try(:production_centre).try(:name)
      # this forces the changed methods to record a change.
      self.changed_attributes['production_centre_name'] = arg
    end
  end

  def production_centre_name=(arg)
    # override included method
    nil
  end

  def production_centre_name
    # override included method
    return nil if parent_colony.blank?
    return parent_colony.mouse_allele_mod.production_centre_name unless parent_colony.mouse_allele_mod.blank?
    return parent_colony.mi_attempt.production_centre_name unless parent_colony.mi_attempt.blank?
    return nil
  end

  def production_consortium_name
    # override included method
    return nil if parent_colony.blank?
    return parent_colony.mouse_allele_mod.consortium_name unless parent_colony.mouse_allele_mod.blank?
    return parent_colony.mi_attempt.consortium_name unless parent_colony.mi_attempt.blank?
    return nil
  end

  def tissue_distribution_centres_attributes
    return tissue_distribution_centres.map(&:as_json) unless tissue_distribution_centres.blank?
    return nil
  end
## CLASS METHODS

  def self.readable_name
    'phenotyping productions'
  end

end

# == Schema Information
#
# Table name: phenotyping_productions
#
#  id                                         :integer          not null, primary key
#  mi_plan_id                                 :integer          not null
#  status_id                                  :integer          not null
#  colony_name                                :string(255)
#  phenotyping_experiments_started            :date
#  phenotyping_started                        :boolean          default(FALSE), not null
#  phenotyping_complete                       :boolean          default(FALSE), not null
#  is_active                                  :boolean          default(TRUE), not null
#  report_to_public                           :boolean          default(TRUE), not null
#  phenotype_attempt_id                       :integer
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  ready_for_website                          :date
#  parent_colony_id                           :integer
#  colony_background_strain_id                :integer
#  rederivation_started                       :boolean          default(FALSE), not null
#  rederivation_complete                      :boolean          default(FALSE), not null
#  cohort_production_centre_id                :integer
#  selected_for_late_adult_phenotyping        :boolean          default(FALSE)
#  late_adult_phenotyping_started             :boolean          default(FALSE)
#  late_adult_phenotyping_complete            :boolean          default(FALSE)
#  late_adult_is_active                       :boolean          default(TRUE)
#  late_adult_report_to_public                :boolean          default(TRUE)
#  late_adult_phenotyping_experiments_started :date
#  late_adult_status_id                       :integer
#  do_not_count_towards_completeness          :boolean          default(FALSE)
#  all_data_sent                              :boolean          default(FALSE)
#  all_data_processed                         :boolean          default(FALSE)
#  qc_complete                                :boolean          default(FALSE)
#

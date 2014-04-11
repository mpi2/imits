# encoding: utf-8

class PhenotypeAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include PhenotypeAttempt::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  QC_FIELDS = [
    :qc_southern_blot,
    :qc_five_prime_lr_pcr,
    :qc_five_prime_cassette_integrity,
    :qc_tv_backbone_assay,
    :qc_neo_count_qpcr,
    :qc_lacz_count_qpcr,
    :qc_neo_sr_pcr,
    :qc_loa_qpcr,
    :qc_homozygous_loa_sr_pcr,
    :qc_lacz_sr_pcr,
    :qc_mutant_specific_sr_pcr,
    :qc_loxp_confirmation,
    :qc_three_prime_lr_pcr,
    :qc_critical_region_qpcr,
    :qc_loxp_srpcr,
    :qc_loxp_srpcr_and_sequencing
  ].freeze

  QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'
    access_association_by_attribute qc_field, :description, :attribute_alias => :result
  end

  def set_blank_qc_fields_to_na
    QC_FIELDS.each do |qc_field|
      if self.send("#{qc_field}_result").blank?
        self.send("#{qc_field}_result=", 'na')
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  belongs_to :mi_plan
  belongs_to :mi_attempt
  belongs_to :status
  belongs_to :deleter_strain
  belongs_to :colony_background_strain, :class_name => 'Strain'

  has_one    :mouse_allele_mod

  has_many   :status_stamps, :order => "#{PhenotypeAttempt::StatusStamp.table_name}.created_at ASC"
  has_many   :distribution_centres, :class_name => 'PhenotypeAttempt::DistributionCentre'
  has_many   :phenotyping_productions
  access_association_by_attribute :colony_background_strain, :name

  accepts_nested_attributes_for :status_stamps

  protected :status=

  validates :mi_attempt, :presence => true
  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
  validates :colony_name, :uniqueness => {:case_sensitive => false}

  before_validation :set_blank_qc_fields_to_na

  # validate mi_plan
  validate do |me|
    if validate_plan

      if !me.mi_plan.phenotype_only and me.mi_attempt and me.mi_attempt.mi_plan != me.mi_plan
        me.errors.add(:mi_plan, 'must be either the same as the mi_attempt OR phenotype_only')
      end

    end
  end


  validate do |me|
    if me.mi_attempt and me.mi_attempt.status != MiAttempt::Status.genotype_confirmed
      me.errors.add(:mi_attempt, "Status must be 'Genotype confirmed' (is currently '#{me.mi_attempt.status.try(:name)}')")
    end
  end

#  validate :validate_plan # this method is in belongs_to_mi_plan



#  validate do |me|
#    if me.mi_attempt and me.mi_plan and me.mi_attempt.gene != me.mi_plan.gene
#      me.errors.add(:mi_plan, 'must have same gene as mi_attempt')
#    end
#  end

#  validate do |me|
#    if me.mi_plan and (!me.mi_plan.phenotype_only or (me.mi_attempt and me.mi_attempt.mi_plan != me.mi_plan))
#      me.errors.add(:mi_plan, 'must be either the same as the mi_attempt OR phenotype_only')
#    end
#  end

  # BEGIN Callbacks
  before_validation do |pa|
    if ! pa.colony_name.nil?
      pa.colony_name = pa.colony_name.to_s.strip || pa.colony_name
      pa.colony_name = pa.colony_name.to_s.gsub(/\s+/, ' ')
    end
  end

  after_initialize :set_mi_plan # need to set mi_plan if blank before authorize_user_production_centre is fired in controller.
  before_validation :allow_override_of_plan
  before_validation :change_status
  before_validation :set_mi_plan # this is here if mi_plan is edited after initialization
  before_validation :check_phenotyping_production_for_update
#  before_save :ensure_plan_exists # this method is in belongs_to_mi_plan
  before_save :deal_with_unassigned_or_inactive_plans # this method is in belongs_to_mi_plan
  before_save :generate_colony_name_if_blank
  after_save :manage_status_stamps
  after_save :set_phenotyping_experiments_started_if_blank
  after_save :set_allele_mod_and_production


## BEFORE VALIDATION FUNCTIONS
  def allow_override_of_plan
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.mi_attempt.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        set_plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end

    self.mi_plan = set_plan
  end


  def check_phenotyping_production_for_update
    linked_pp = []
    deleting_pp = []
    self.phenotyping_productions.each{|pp| linked_pp << pp if pp.consortium_name == self.consortium_name and pp.production_centre_name == self.production_centre_name and !pp.marked_for_destruction?}
    self.phenotyping_productions.each{|pp| deleting_pp << pp if pp.consortium_name == self.consortium_name and pp.production_centre_name == self.production_centre_name and pp.marked_for_destruction?}
    if linked_pp.count == 1
      pp_changes = linked_pp.first.changes
      PhenotypingProduction.phenotype_attempt_updatable_fields.each do |field, default_value|
        if pp_changes.has_key?(field)
          self[field] = pp_changes[field][1]
        end
      end
    elsif deleting_pp.count >= 1
      PhenotypingProduction.phenotype_attempt_updatable_fields.each do |field, default_value|
        self[field] = default_value
      end
    end
  end

## AFTER SAVE FUNCTIONS
  def set_allele_mod_and_production

    mouse_allele = MouseAlleleMod.create_or_update_from_phenotype_attempt(self)
    self.reload
    if self.phenotyping_productions.count == 0
      PhenotypingProduction.create_or_update_from_phenotype_attempt(self)
      self.reload
    end

    linked_pp = []
    self.phenotyping_productions.each{|pp| linked_pp << pp if pp.consortium_name == self.consortium_name and pp.production_centre_name == self.production_centre_name and !pp.marked_for_destruction?}
    if linked_pp.count == 1
      PhenotypingProduction.phenotype_attempt_updatable_fields.each do |field, default_value|
        if self[field] != linked_pp.first[field]
          linked_pp.first[field] = self[field]
        end
        linked_pp.first.save
      end
    end
  end

  def set_mi_plan
    if ! self.mi_plan.present?
      self.mi_plan = self.try(:mi_attempt).try(:mi_plan)
    end
  end

  def set_phenotyping_experiments_started_if_blank
    if self.phenotyping_experiments_started.blank? and self.status_stamps.where("status_id = 7").count !=0
      self.phenotyping_experiments_started = self.status_stamps.where("status_id = 7").first.try(:created_at).try(:to_date) #Phenotype Started
      self.save
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?
    i = 0
    begin
      i += 1
      self.colony_name = "#{self.mi_attempt.colony_name}-#{i}"
    end until self.class.find_by_colony_name(self.colony_name).blank?
  end

  # END Callbacks

  def distribution_centres_formatted_display
    output_string = ''
    self.distribution_centres.each do |distribution_centre|
      output_array = []
      if distribution_centre.is_distributed_by_emma
        output_array << 'EMMA'
      end
      output_array << distribution_centre.centre.name
      if !distribution_centre.deposited_material.name.nil?
        output_array << distribution_centre.deposited_material.name
      end
      output_string << "[#{output_array.join(', ')}] "
    end
    return output_string.strip()
  end

  def mouse_allele_symbol_superscript
    if mouse_allele_type.nil? or self.mi_attempt.es_cell.allele_symbol_superscript_template.nil?
      return nil
    else
      return self.es_cell.allele_symbol_superscript_template.sub(
        TargRep::EsCell::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_symbol
    if mouse_allele_symbol_superscript
      return "#{self.gene.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"
    else
      return nil
    end
  end

  def allele_symbol
    if has_status?(:cec)
      return mouse_allele_symbol
    else
      return self.mi_attempt.allele_symbol
    end
  end

  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif mi_attempt.try(:gene)
      return mi_attempt.gene
    else
      return nil
    end
  end

  def mi_attempt_colony_background_strain_name
    mi_attempt.try(:colony_background_strain).try(:name)
  end

  def mi_attempt_colony_background_mgi_strain_accession_id
    mi_attempt.try(:colony_background_strain).try(:mgi_strain_accession_id)
  end

  def mi_attempt_colony_background_mgi_strain_name
    mi_attempt.try(:colony_background_strain).try(:mgi_strain_name)
  end

  def colony_background_strain_mgi_accession
    return colony_background_strain.try(:mgi_strain_accession_id)
  end

  def colony_background_strain_mgi_name
    return colony_background_strain.try(:mgi_strain_name)
  end

  def mgi_accession_id
    return mi_plan.try(:gene).try(:mgi_accession_id)
  end


  delegate :consortium, :production_centre, :to => :mi_plan, :allow_nil => true
  delegate :marker_symbol, :to => :gene, :allow_nil => true
  delegate :es_cell, :allele_id, :to => :mi_attempt, :allow_nil => true

  def reportable_statuses_with_latest_dates
    retval = {}
    status_stamps.each do |status_stamp|
      status_stamp_date = status_stamp.created_at.utc.to_date
      if !retval[status_stamp.status.name] or
                status_stamp_date > retval[status_stamp.status.name]
        retval[status_stamp.status.name] = status_stamp_date
      end
    end
    return retval
  end

  def in_progress_date
    return status_stamps.all.find {|ss| ss.status_id == 2}.created_at.utc.to_date   #Phenotype Attempt Registered
  end

  def earliest_relevant_status_stamp
    self.status_stamps.find_by_status_id(self.status_id)
  end

  def self.readable_name
    'phenotype attempt'
  end
end

#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                                  :integer          not null, primary key
#  mi_attempt_id                       :integer          not null
#  status_id                           :integer          not null
#  is_active                           :boolean          default(TRUE), not null
#  rederivation_started                :boolean          default(FALSE), not null
#  rederivation_complete               :boolean          default(FALSE), not null
#  number_of_cre_matings_started       :integer          default(0), not null
#  number_of_cre_matings_successful    :integer          default(0), not null
#  phenotyping_started                 :boolean          default(FALSE), not null
#  phenotyping_complete                :boolean          default(FALSE), not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  mi_plan_id                          :integer          not null
#  colony_name                         :string(125)      not null
#  mouse_allele_type                   :string(3)
#  deleter_strain_id                   :integer
#  colony_background_strain_id         :integer
#  cre_excision_required               :boolean          default(TRUE), not null
#  tat_cre                             :boolean          default(FALSE)
#  report_to_public                    :boolean          default(TRUE), not null
#  phenotyping_experiments_started     :date
#  qc_southern_blot_id                 :integer
#  qc_five_prime_lr_pcr_id             :integer
#  qc_five_prime_cassette_integrity_id :integer
#  qc_tv_backbone_assay_id             :integer
#  qc_neo_count_qpcr_id                :integer
#  qc_neo_sr_pcr_id                    :integer
#  qc_loa_qpcr_id                      :integer
#  qc_homozygous_loa_sr_pcr_id         :integer
#  qc_lacz_sr_pcr_id                   :integer
#  qc_mutant_specific_sr_pcr_id        :integer
#  qc_loxp_confirmation_id             :integer
#  qc_three_prime_lr_pcr_id            :integer
#  qc_lacz_count_qpcr_id               :integer
#  qc_critical_region_qpcr_id          :integer
#  qc_loxp_srpcr_id                    :integer
#  qc_loxp_srpcr_and_sequencing_id     :integer
#  allele_name                         :string(255)
#  jax_mgi_accession_id                :string(255)
#  ready_for_website                   :date
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

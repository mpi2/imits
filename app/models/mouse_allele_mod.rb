# encoding: utf-8

class MouseAlleleMod < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MouseAlleleMod::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :parent_colony, :class_name => 'Colony'
  belongs_to :allele
  belongs_to :real_allele
  belongs_to :mi_plan
  belongs_to :status
  belongs_to :deleter_strain
  belongs_to :colony_background_strain, :class_name => 'Strain'


  has_many   :status_stamps, :order => "#{MouseAlleleMod::StatusStamp.table_name}.created_at ASC", dependent: :destroy
  has_many   :distribution_centres, :class_name => 'PhenotypeAttempt::DistributionCentre'

  has_one    :colony, dependent: :destroy

  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :deleter_strain, :name


  ColonyQc::QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'

    define_method("#{qc_field}_result=") do |arg|
      instance_variable_set("@#{qc_field}_result",arg)
    end

    define_method("#{qc_field}_result") do
      if !instance_variable_get("@#{qc_field}_result").blank?
        return instance_variable_get("@#{qc_field}_result")
      elsif !colony.blank? and !colony.try(:colony_qc).try(qc_field.to_sym).blank?
        return colony.colony_qc.send(qc_field)
      else
        return 'na'
      end
    end
  end

  accepts_nested_attributes_for :status_stamps, :colony

  protected :status=

  before_validation :set_blank_qc_fields_to_na
  before_validation :allow_override_of_plan
  before_validation :change_status
  before_validation :manage_colony_and_qc_data

  before_destroy :remove_links_to_distribution_centres
  after_save :set_distribution_centre
  after_save :manage_status_stamps

## METHODS
  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif parent_colony.try(:gene)
      return parent_colony.gene
    else
      return nil
    end
  end

  def colony_name
    if !@colony_name.blank?
      @colony_name
    elsif !colony.blank?
      colony.name
    else
      nil
    end
  end

  def colony_name=(arg)
    @colony_name = arg
  end


## BEFORE VALIDATION FUNCTIONS
  def set_blank_qc_fields_to_na
    ColonyQc::QC_FIELDS.each do |qc_field|
      if self.send("#{qc_field}_result").blank?
        self.send("#{qc_field}_result=", 'na')
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  def allow_override_of_plan
    return if self.consortium_name.blank? or self.production_centre_name.blank? or self.gene.blank?
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.parent_colony.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end

    self.mi_plan = set_plan
  end
  protected :allow_override_of_plan

  def manage_colony_and_qc_data

    colony_attr_hash = colony.try(:attributes) || {}
    if colony.blank? or (colony.try(:name) != colony_name)
      colony_attr_hash[:name] = colony_name
    end

    colony_attr_hash[:id] = colony.id if !colony.blank?

    if self.status.try(:code) == 'cec'
      colony_attr_hash[:genotype_confirmed] = true
    elsif self.status.try(:code) != 'cec'
      colony_attr_hash[:genotype_confirmed] = false
    end

    colony_attr_hash[:colony_qc_attributes] = {} if !colony_attr_hash.has_key?(:colony_qc_attributes)
    colony_attr_hash[:colony_qc_attributes][:id] = colony.colony_qc.id if !colony.blank? and !colony.try(:colony_qc).try(:id).blank?

    ColonyQc::QC_FIELDS.each do |qc_field|
      if colony.try(:colony_qc).blank? or self.send("#{qc_field}_result") != colony.colony_qc.send(qc_field)
        colony_attr_hash[:colony_qc_attributes]["#{qc_field}".to_sym] = self.send("#{qc_field}_result")
      end
    end

    self.colony_attributes = colony_attr_hash

  end
  protected :manage_colony_and_qc_data


## TO DO WHEN removing phenotype_attempt table

## AFTER SAVE FUNCTIONS
#  def set_distribution_centre
#    phenotype_attempt = self.phenotype_attempt

#    phenotype_attempt.distribution_centres.where("mouse_allele_mod_id != #{self.id} OR mouse_allele_mod_id IS NULL").each do |distribution_centre|
#      distribution_centre.mouse_allele_mod_id = self.id if distribution_centre.mouse_allele_mod_id.blank?
#      distribution_centre.save
#    end
#  end
#  protected :set_distribution_centre

## BEFORE DELETION
  def remove_links_to_distribution_centres

    self.distribution_centres.each do |distribution_centre|
      distribution_centre.mouse_allele_mod_id = nil
      distribution_centre.save
    end
  end
  protected :remove_links_to_distribution_centres

## CLASS METHODS
  def self.create_or_update_from_phenotype_attempt(phenotype_attempt)
    raise PhenotypeAttemptError, "Must pass phenotype_attempt as a parameter." if phenotype_attempt.blank?

    params = {:mi_plan_id                       => phenotype_attempt.mi_plan_id,
              :parent_colony                    => phenotype_attempt.parent_colony,
              :rederivation_started             => phenotype_attempt.rederivation_started,
              :rederivation_complete            => phenotype_attempt.rederivation_complete,
              :number_of_cre_matings_started    => phenotype_attempt.number_of_cre_matings_started,
              :number_of_cre_matings_successful => phenotype_attempt.number_of_cre_matings_successful,
              :mouse_allele_type                => phenotype_attempt.mouse_allele_type,
              :deleter_strain_id                => phenotype_attempt.deleter_strain_id,
              :colony_background_strain_id      => phenotype_attempt.colony_background_strain_id,
              :excision                         => phenotype_attempt.cre_excision_required,
              :tat_cre                          => phenotype_attempt.tat_cre,
              :colony_name                      => phenotype_attempt.colony_name,
              :is_active                        => phenotype_attempt.is_active,
              :report_to_public                 => phenotype_attempt.report_to_public,
              :consortium_name                  => phenotype_attempt.consortium_name,
              :production_centre_name           => phenotype_attempt.production_centre_name,
              :no_modification_required         => ! phenotype_attempt.cre_excision_required,
              :qc_southern_blot_result          => phenotype_attempt.qc_southern_blot_result,
              :qc_five_prime_lr_pcr_result      => phenotype_attempt.qc_five_prime_lr_pcr_result,
              :qc_five_prime_cassette_integrity_result => phenotype_attempt.qc_five_prime_cassette_integrity_result,
              :qc_tv_backbone_assay_result      => phenotype_attempt.qc_tv_backbone_assay_result,
              :qc_neo_count_qpcr_result         => phenotype_attempt.qc_neo_count_qpcr_result,
              :qc_neo_sr_pcr_result             => phenotype_attempt.qc_neo_sr_pcr_result,
              :qc_loa_qpcr_result               => phenotype_attempt.qc_loa_qpcr_result,
              :qc_homozygous_loa_sr_pcr_result  => phenotype_attempt.qc_homozygous_loa_sr_pcr_result,
              :qc_lacz_sr_pcr_result            => phenotype_attempt.qc_lacz_sr_pcr_result,
              :qc_mutant_specific_sr_pcr_result => phenotype_attempt.qc_mutant_specific_sr_pcr_result,
              :qc_loxp_confirmation_result      => phenotype_attempt.qc_loxp_confirmation_result,
              :qc_three_prime_lr_pcr_result     => phenotype_attempt.qc_three_prime_lr_pcr_result,
              :qc_lacz_count_qpcr_result        => phenotype_attempt.qc_lacz_count_qpcr_result,
              :qc_critical_region_qpcr_result   => phenotype_attempt.qc_critical_region_qpcr_result,
              :qc_loxp_srpcr_result             => phenotype_attempt.qc_loxp_srpcr_result,
              :qc_loxp_srpcr_and_sequencing_result => phenotype_attempt.qc_loxp_srpcr_and_sequencing_result,
              :allele_name                      => phenotype_attempt.allele_name,
              :allele_mgi_accession_id          => phenotype_attempt.jax_mgi_accession_id,
              :allele_id                        => phenotype_attempt.allele_id,
              :real_allele_id                   => phenotype_attempt.real_allele_id
              }
    mam = phenotype_attempt.mouse_allele_mod || MouseAlleleMod.new
    mam.update_attributes(params)
    if mam.valid?

      status_mapping = {
                        'Phenotype Attempt Registered'         => 'Phenotype Attempt Registered',
                        'Mouse Allele Modification Registered' => 'Phenotype Attempt Registered',
                        'Rederivation Started'                 => 'Rederivation Started',
                        'Rederivation Complete'                => 'Rederivation Complete',
                        'Cre Excision Started'                 => 'Cre Excision Started',
                        'Cre Excision Complete'                => 'Cre Excision Complete',
                        'Mouse Allele Modification Aborted'    => 'Phenotype Attempt Aborted'
                       }
      phenotype_status_stamps = {}
      mam.phenotype_attempt.status_stamps.includes(:status).each{|stamp| phenotype_status_stamps[stamp.status.name] = stamp.created_at}
      mam.status_stamps.includes(:status).each{|stamp| stamp.update_attributes(:created_at => phenotype_status_stamps[status_mapping[stamp.status.name]]) if phenotype_status_stamps.has_key?(status_mapping[stamp.status.name])}
    else
      raise PhenotypeAttemptError, "failed to save Mouse Allele Mod #{mam.errors.messages}."
    end
  end

  def mouse_allele_symbol_superscript
    return nil unless colony
    return colony.allele_symbol_superscript
  end

  def mouse_allele_symbol
    return nil unless colony
    return colony.allele_symbol
  end


  def mi_attempt
    col = parent_colony

    while col.mi_attempt_id.blank? && !col.mouse_allele_mod_id.blank?
      col = col.mouse_allele_mod.parent_colony
    end

    return col.mi_attempt
  end


  def self.readable_name
    'mouse allele modification'
  end
end

# == Schema Information
#
# Table name: mouse_allele_mods
#
#  id                                  :integer          not null, primary key
#  mi_plan_id                          :integer          not null
#  mi_attempt_id                       :integer          not null
#  status_id                           :integer          not null
#  rederivation_started                :boolean          default(FALSE), not null
#  rederivation_complete               :boolean          default(FALSE), not null
#  number_of_cre_matings_started       :integer          default(0), not null
#  number_of_cre_matings_successful    :integer          default(0), not null
#  no_modification_required            :boolean          default(FALSE)
#  cre_excision                        :boolean          default(TRUE), not null
#  tat_cre                             :boolean          default(FALSE)
#  mouse_allele_type                   :string(3)
#  allele_category                     :string(255)
#  deleter_strain_id                   :integer
#  colony_background_strain_id         :integer
#  colony_name                         :string(125)      not null
#  is_active                           :boolean          default(TRUE), not null
#  report_to_public                    :boolean          default(TRUE), not null
#  phenotype_attempt_id                :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
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
#  allele_id                           :integer
#  real_allele_id                      :integer
#  allele_name                         :string(255)
#  allele_mgi_accession_id             :string(255)
#  parent_colony_id                    :integer
#

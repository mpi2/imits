# encoding: utf-8

class MouseAlleleMod < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MouseAlleleMod::StatusManagement
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  belongs_to :mi_plan
  belongs_to :mi_attempt
  belongs_to :phenotype_attempt
  belongs_to :status
  belongs_to :deleter_strain
  belongs_to :colony_background_strain, :class_name => 'Strain'

  has_many   :status_stamps, :order => "#{MouseAlleleMod::StatusStamp.table_name}.created_at ASC", dependent: :destroy
  has_many   :phenotyping_productions
  has_many   :distribution_centres, :class_name => 'PhenotypeAttempt::DistributionCentre'

  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :deleter_strain, :name

  accepts_nested_attributes_for :status_stamps

  protected :status=

  before_validation :allow_override_of_plan
  before_validation :set_allele_category
  before_validation :change_status

  before_destroy :remove_links_to_distribution_centres
  after_save :set_distribution_centre
  after_save :manage_status_stamps

#  validates :mi_attempt, :presence => true
#  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
#  validates :colony_name, :uniqueness => {:case_sensitive => false}

  # validate mi_plan
#  validate do |me|
#    if validate_plan

#      if !me.mi_plan.phenotype_only and me.mi_attempt and me.mi_attempt.mi_plan != me.mi_plan
#        me.errors.add(:mi_plan, 'must be either the same as the mi_attempt OR phenotype_only')
#      end

#    end
#  end


#  validate do |me|
#    if me.mi_attempt and me.mi_attempt.status != MiAttempt::Status.genotype_confirmed
#      me.errors.add(:mi_attempt, "Status must be 'Genotype confirmed' (is currently '#{me.mi_attempt.status.try(:name)}')")
#    end
#  end

  # BEGIN Callbacks
#  before_validation do |pa|
#    if ! pa.colony_name.nil?
#      pa.colony_name = pa.colony_name.to_s.strip || pa.colony_name
#      pa.colony_name = pa.colony_name.to_s.gsub(/\s+/, ' ')
#    end
#  end

#  after_initialize :set_mi_plan # need to set mi_plan if blank before authorize_user_production_centre is fired in controller.

#  before_validation :set_mi_plan # this is here if mi_plan is edited after initialization
#  before_save :deal_with_unassigned_or_inactive_plans # this method is in belongs_to_mi_plan
#  before_save :generate_colony_name_if_blank

## METHODS
  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif phenotype_attempt.try(:gene)
      return phenotype_attempt.gene
    else
      return nil
    end
  end


## BEFORE VALIDATION FUNCTIONS
  def allow_override_of_plan
    set_plan = MiPlan.find_or_create_plan(self, {:gene => self.gene, :consortium_name => self.consortium_name, :production_centre_name => self.production_centre_name, :phenotype_only => true}) do |pa|
      plan = pa.mi_attempt.mi_plan
      if !plan.blank? and plan.consortium.try(:name) == self.consortium_name and plan.production_centre.try(:name) == self.production_centre_name
        plan = [plan]
      else
        plan = MiPlan.includes(:consortium, :production_centre, :gene).where("genes.marker_symbol = '#{self.gene.marker_symbol}' AND consortia.name = '#{self.consortium_name}' AND centres.name = '#{self.production_centre_name}' AND phenotype_only = true")
      end
    end

    self.mi_plan = set_plan
  end

  def set_allele_category
    if self.cre_excision
      self.allele_category = 'tm1b'
    else
      self.allele_category = 'tm1a'
    end
  end


## AFTER SAVE FUNCTIONS
  def set_distribution_centre
    phenotype_attempt = self.phenotype_attempt

    phenotype_attempt.distribution_centres.where("mouse_allele_mod_id != #{self.id} OR mouse_allele_mod_id IS NULL").each do |distribution_centre|
      distribution_centre.mouse_allele_mod_id = self.id if distribution_centre.mouse_allele_mod_id.blank?
      distribution_centre.save
    end
  end


## BEFORE DELETION
  def remove_links_to_distribution_centres

    self.distribution_centres.each do |distribution_centre|
      distribution_centre.mouse_allele_mod_id = nil
      distribution_centre.save
    end
  end

## CLASS METHODS
  def self.create_or_update_from_phenotype_attempt(phenotype_attempt)
    raise PhenotypeAttemptError, "Must pass phenotype_attempt as a parameter." if phenotype_attempt.blank?

    params = {:mi_plan_id                       => phenotype_attempt.mi_plan_id,
              :mi_attempt_id                    => phenotype_attempt.mi_attempt_id,
              :phenotype_attempt_id             => phenotype_attempt.id,
              :rederivation_started             => phenotype_attempt.rederivation_started,
              :rederivation_complete            => phenotype_attempt.rederivation_complete,
              :number_of_cre_matings_started    => phenotype_attempt.number_of_cre_matings_started,
              :number_of_cre_matings_successful => phenotype_attempt.number_of_cre_matings_successful,
              :mouse_allele_type                => phenotype_attempt.mouse_allele_type,
              :deleter_strain_id                => phenotype_attempt.deleter_strain_id,
              :colony_background_strain_id      => phenotype_attempt.colony_background_strain_id,
              :cre_excision                     => phenotype_attempt.cre_excision_required,
              :tat_cre                          => phenotype_attempt.tat_cre,
              :colony_name                      => phenotype_attempt.colony_name,
              :is_active                        => phenotype_attempt.is_active,
              :report_to_public                 => phenotype_attempt.report_to_public,
              :consortium_name                  => phenotype_attempt.consortium_name,
              :production_centre_name           => phenotype_attempt.production_centre_name,
              :no_modification_required         => ! phenotype_attempt.cre_excision_required,
              :qc_southern_blot_id              => phenotype_attempt.qc_southern_blot_id,
              :qc_five_prime_lr_pcr_id          => phenotype_attempt.qc_five_prime_lr_pcr_id,
              :qc_five_prime_cassette_integrity_id => phenotype_attempt.qc_five_prime_cassette_integrity_id,
              :qc_tv_backbone_assay_id          => phenotype_attempt.qc_tv_backbone_assay_id,
              :qc_neo_count_qpcr_id             => phenotype_attempt.qc_neo_count_qpcr_id,
              :qc_neo_sr_pcr_id                 => phenotype_attempt.qc_neo_sr_pcr_id,
              :qc_loa_qpcr_id                   => phenotype_attempt.qc_loa_qpcr_id,
              :qc_homozygous_loa_sr_pcr_id      => phenotype_attempt.qc_homozygous_loa_sr_pcr_id,
              :qc_lacz_sr_pcr_id                => phenotype_attempt.qc_lacz_sr_pcr_id,
              :qc_mutant_specific_sr_pcr_id     => phenotype_attempt.qc_mutant_specific_sr_pcr_id,
              :qc_loxp_confirmation_id          => phenotype_attempt.qc_loxp_confirmation_id,
              :qc_three_prime_lr_pcr_id         => phenotype_attempt.qc_three_prime_lr_pcr_id,
              :qc_lacz_count_qpcr_id            => phenotype_attempt.qc_lacz_count_qpcr_id,
              :qc_critical_region_qpcr_id       => phenotype_attempt.qc_critical_region_qpcr_id,
              :qc_loxp_srpcr_id                 => phenotype_attempt.qc_loxp_srpcr_id,
              :qc_loxp_srpcr_and_sequencing_id  => phenotype_attempt.qc_loxp_srpcr_and_sequencing_id
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
#

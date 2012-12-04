# encoding: utf-8

class MiAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiAttempt::StatusManagement
  include MiAttempt::WarningGenerator
  include ApplicationModel::HasStatuses

  QC_FIELDS = [
    :qc_southern_blot,
    :qc_five_prime_lr_pcr,
    :qc_five_prime_cassette_integrity,
    :qc_tv_backbone_assay,
    :qc_neo_count_qpcr,
    :qc_neo_sr_pcr,
    :qc_loa_qpcr,
    :qc_homozygous_loa_sr_pcr,
    :qc_lacz_sr_pcr,
    :qc_mutant_specific_sr_pcr,
    :qc_loxp_confirmation,
    :qc_three_prime_lr_pcr
  ].freeze

  belongs_to :mi_plan
  belongs_to :es_cell
  belongs_to :status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :blast_strain, :class_name => 'Strain'
  belongs_to :colony_background_strain, :class_name => 'Strain'
  belongs_to :test_cross_strain, :class_name => 'Strain'

  has_many :status_stamps, :order => "#{MiAttempt::StatusStamp.table_name}.created_at ASC"
  has_many :phenotype_attempts

  has_many :distribution_centres, :class_name => 'MiAttempt::DistributionCentre'

  access_association_by_attribute :blast_strain, :name
  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :test_cross_strain, :name

  QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'
    access_association_by_attribute qc_field, :description, :attribute_alias => :result
  end

  protected :status=

  validates :es_cell_name, :presence => true
  validates :production_centre_name, :presence => true
  validates :consortium_name, :presence => true
  validates :status, :presence => true
  validates :colony_name, :uniqueness => {:case_sensitive => false}, :allow_nil => true
  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
  validates :mi_date, :presence => true

  validate do |mi|
    if !mi.es_cell_name.blank? and mi.es_cell.blank?
      mi.errors.add :es_cell_name, 'was not found in the marts'
    end
  end

  validate do |mi|
    next unless mi.mi_plan

    if mi.mi_plan.production_centre.blank?
      mi.errors.add :mi_plan, 'must have a production centre (INTERNAL ERROR)'
    end
  end

  validate do |mi|
    matching_mi_plan = find_matching_mi_plan

    if matching_mi_plan and
              matching_mi_plan.status == MiPlan::Status['Aborted - ES Cell QC Failed']
      error = 'ES cells failed QC'
      mi.errors.add :base, error
    end
  end

  validate do |mi_attempt|
    if ! Consortium.find_by_name(mi_attempt.consortium_name)
      mi_attempt.errors.add :consortium_name, 'does not exist'
    end
    if ! Centre.find_by_name(mi_attempt.production_centre_name)
      mi_attempt.errors.add :production_centre_name, 'does not exist'
    end
  end

  validate do |mi_attempt|
    next unless mi_attempt.es_cell and mi_attempt.mi_plan and mi_attempt.es_cell.gene and mi_attempt.mi_plan.gene
    if(mi_attempt.es_cell.gene != mi_attempt.mi_plan.gene)
      mi_attempt.errors.add :base, "mi_plan and es_cell gene mismatch!  Should be the same! (#{mi_attempt.es_cell.gene.marker_symbol} != #{mi_attempt.mi_plan.gene.marker_symbol})"
    end
  end

  validate do |mi_attempt|
    if !mi_attempt.phenotype_attempts.blank? and
              mi_attempt.status != MiAttempt::Status.genotype_confirmed
      mi_attempt.errors.add(:status, 'cannot be changed - phenotype attempts exist')
    end
  end

  # BEGIN Callbacks

  before_validation :set_blank_qc_fields_to_na
  before_validation :set_total_chimeras
  before_validation :set_es_cell_from_es_cell_name
  before_validation :change_status

  before_validation do |mi|
    if ! mi.colony_name.nil?
      mi.colony_name = mi.colony_name.to_s.strip || mi.colony_name
      mi.colony_name = mi.colony_name.to_s.gsub(/\s+/, ' ')
    end
  end

  before_save :generate_colony_name_if_blank
  before_save :set_mi_plan

  after_save :manage_status_stamps
  after_save :reload_mi_plan_mi_attempts

  protected

  def set_total_chimeras
    self.total_chimeras = total_male_chimeras.to_i + total_female_chimeras.to_i
  end

  def set_es_cell_from_es_cell_name
    if ! self.es_cell
      self.es_cell = EsCell.find_or_create_from_marts_by_name(self.es_cell_name)
    end
  end

  def set_blank_qc_fields_to_na
    QC_FIELDS.each do |qc_field|
      if self.send("#{qc_field}_result").blank?
        self.send("#{qc_field}_result=", 'na')
      end
    end
  end

  def generate_colony_name_if_blank
    return unless self.colony_name.blank?

    i = 0
    begin
      i += 1
      self.colony_name = "#{self.production_centre_name}-#{self.es_cell_name}-#{i}"
    end until self.class.find_by_colony_name(self.colony_name).blank?
  end

  def set_mi_plan
    mi_plan_to_set = find_matching_mi_plan
    if ! mi_plan_to_set
      mi_plan_to_set = MiPlan.new
      mi_plan_to_set.priority = MiPlan::Priority.find_by_name!('High')
      mi_plan_to_set.consortium = Consortium.find_by_name!(consortium_name)
      mi_plan_to_set.gene = es_cell.gene
    end

    mi_plan_to_set.production_centre = Centre.find_by_name!(production_centre_name)

    if is_active?
      mi_plan_to_set.is_active = true
    end

    mi_plan_to_set.force_assignment = true
    mi_plan_to_set.save!

    self.mi_plan = mi_plan_to_set
  end

  def reload_mi_plan_mi_attempts
    mi_plan.mi_attempts.reload
  end

  public

  # END Callbacks

  def self.active
    where(:is_active => true)
  end

  def self.genotype_confirmed
    where(:status_id => MiAttempt::Status.genotype_confirmed.id)
  end

  def self.in_progress
    where(:status_id => MiAttempt::Status.micro_injection_in_progress.id)
  end

  def self.aborted
    where(:status_id => MiAttempt::Status.micro_injection_aborted.id)
  end

  def consortium_name
    if ! @consortium_name.blank?
      return @consortium_name
    else
      if self.mi_plan
        @consortium_name = self.mi_plan.consortium.name
      end
    end
  end

  def consortium_name=(arg)
    @consortium_name = arg
  end

  def production_centre_name
    if ! @production_centre_name.blank?
      return @production_centre_name
    else
      if self.mi_plan
        @production_centre_name = self.mi_plan.production_centre.try(:name)
      end
    end
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end

  def production_centre_name=(arg)
    @production_centre_name = arg
  end

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

  def es_cell_name
    if(self.es_cell)
      return self.es_cell.name
    else
      return @es_cell_name
    end
  end

  def es_cell_name=(arg)
    if(! self.es_cell)
      @es_cell_name = arg
    end
  end

  def create_phenotype_attempt_for_komp2
    consortia_to_check = ["BaSH", "DTCC", "JAX"]
    if self.status.name == "Genotype confirmed" && consortia_to_check.include?(self.consortium.name)
      if self.phenotype_attempts.empty?
        self.phenotype_attempts.create!
      end
    end
  end

  def add_status_stamp(new_status)
    self.status_stamps.create!(:status => new_status)
    self.status_stamps.reload
  end
  private :add_status_stamp

  def reportable_statuses_with_latest_dates
    retval = {}
    status_stamps.each do |status_stamp|
      status_stamp_date = status_stamp.created_at.utc.to_date
      retval[status_stamp.name] = status_stamp_date
    end

    return retval
  end

  def mouse_allele_symbol_superscript
    if mouse_allele_type.nil? or es_cell.allele_symbol_superscript_template.nil?
      return nil
    else
      return es_cell.allele_symbol_superscript_template.sub(
        EsCell::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_symbol
    if mouse_allele_symbol_superscript
      return "#{es_cell.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"
    else
      return nil
    end
  end

  def allele_symbol
    if mouse_allele_type
      return mouse_allele_symbol
    else
      return es_cell.allele_symbol
    end
  end

  delegate :gene, :to => :es_cell

  def es_cell_marker_symbol; es_cell.try(:marker_symbol); end
  def es_cell_allele_symbol; es_cell.try(:allele_symbol); end

  delegate :production_centre, :consortium, :to => :mi_plan

  def find_matching_mi_plan
    consortium = Consortium.find_by_name(consortium_name)
    production_centre = Centre.find_by_name(production_centre_name)
    return unless es_cell and consortium and production_centre

    if mi_plan
      if consortium == mi_plan.consortium and production_centre == mi_plan.production_centre
        return mi_plan
      end
    end

    lookup_conditions = {
      :gene_id => es_cell.gene.id,
      :consortium_id => consortium.id,
      :production_centre_id => production_centre.id
    }
    mi_plan = MiPlan.where(lookup_conditions).first
    if ! mi_plan
      lookup_conditions[:production_centre_id] = nil
      mi_plan = MiPlan.where(lookup_conditions).first
    end

    return mi_plan
  end

  def self.translations
    return {
      'es_cell_marker_symbol'   => 'es_cell_gene_marker_symbol',
      'es_cell_allele_symbol'   => 'es_cell_gene_allele_symbol',
      'consortium_name'         => 'mi_plan_consortium_name',
      'production_centre_name'  => 'mi_plan_production_centre_name'
    }
  end

  def self.public_search(params)
    translated_params = {}
    params.stringify_keys.each do |name, value|
      translated_params[translate_public_param(name)] = value
    end
    return self.search(translated_params)
  end

  def in_progress_date
    return status_stamps.all.find {|ss| ss.status_id == MiAttempt::Status.micro_injection_in_progress.id}.created_at.utc.to_date
  end

  def allele_id
    es_cell.allele_id
  end

  def self.readable_name
    return 'micro-injection attempt'
  end

end

# == Schema Information
#
# Table name: mi_attempts
#
#  id                                              :integer         not null, primary key
#  es_cell_id                                      :integer         not null
#  mi_date                                         :date            not null
#  status_id                                       :integer         not null
#  colony_name                                     :string(125)
#  updated_by_id                                   :integer
#  blast_strain_id                                 :integer
#  total_blasts_injected                           :integer
#  total_transferred                               :integer
#  number_surrogates_receiving                     :integer
#  total_pups_born                                 :integer
#  total_female_chimeras                           :integer
#  total_male_chimeras                             :integer
#  total_chimeras                                  :integer
#  number_of_males_with_0_to_39_percent_chimerism  :integer
#  number_of_males_with_40_to_79_percent_chimerism :integer
#  number_of_males_with_80_to_99_percent_chimerism :integer
#  number_of_males_with_100_percent_chimerism      :integer
#  colony_background_strain_id                     :integer
#  test_cross_strain_id                            :integer
#  date_chimeras_mated                             :date
#  number_of_chimera_matings_attempted             :integer
#  number_of_chimera_matings_successful            :integer
#  number_of_chimeras_with_glt_from_cct            :integer
#  number_of_chimeras_with_glt_from_genotyping     :integer
#  number_of_chimeras_with_0_to_9_percent_glt      :integer
#  number_of_chimeras_with_10_to_49_percent_glt    :integer
#  number_of_chimeras_with_50_to_99_percent_glt    :integer
#  number_of_chimeras_with_100_percent_glt         :integer
#  total_f1_mice_from_matings                      :integer
#  number_of_cct_offspring                         :integer
#  number_of_het_offspring                         :integer
#  number_of_live_glt_offspring                    :integer
#  mouse_allele_type                               :string(2)
#  qc_southern_blot_id                             :integer
#  qc_five_prime_lr_pcr_id                         :integer
#  qc_five_prime_cassette_integrity_id             :integer
#  qc_tv_backbone_assay_id                         :integer
#  qc_neo_count_qpcr_id                            :integer
#  qc_neo_sr_pcr_id                                :integer
#  qc_loa_qpcr_id                                  :integer
#  qc_homozygous_loa_sr_pcr_id                     :integer
#  qc_lacz_sr_pcr_id                               :integer
#  qc_mutant_specific_sr_pcr_id                    :integer
#  qc_loxp_confirmation_id                         :integer
#  qc_three_prime_lr_pcr_id                        :integer
#  report_to_public                                :boolean         default(TRUE), not null
#  is_active                                       :boolean         default(TRUE), not null
#  is_released_from_genotyping                     :boolean         default(FALSE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer         not null
#  genotyping_comment                              :string(512)
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (colony_name) UNIQUE
#


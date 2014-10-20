# encoding: utf-8

class MiAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiAttempt::StatusManagement
  include MiAttempt::WarningGenerator
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

  belongs_to :real_allele
  belongs_to :mi_plan
  belongs_to :es_cell, :class_name => 'TargRep::EsCell'
  belongs_to :status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :blast_strain, :class_name => 'Strain'
  belongs_to :colony_background_strain, :class_name => 'Strain'
  belongs_to :test_cross_strain, :class_name => 'Strain'
  belongs_to :mutagenesis_factor, :inverse_of => :mi_attempt

  has_one    :colony, inverse_of: :mi_attempt

  has_many   :status_stamps, :order => "#{MiAttempt::StatusStamp.table_name}.created_at ASC"
  has_many   :phenotype_attempts
  has_many   :mouse_allele_mods
  has_many   :colonies, inverse_of: :mi_attempt
  has_many   :distribution_centres, :class_name => 'MiAttempt::DistributionCentre'
  has_many   :crisprs, through: :mutagenesis_factor
  has_many   :genotype_primers, through: :mutagenesis_factor

  access_association_by_attribute :blast_strain, :name
  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :test_cross_strain, :name

  QC_FIELDS.each do |qc_field|
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

  accepts_nested_attributes_for :status_stamps, :mutagenesis_factor, :colony
  accepts_nested_attributes_for :colonies, :allow_destroy => true

  protected :status=

  validates :status, :presence => true
  validates :external_ref, :uniqueness => {:case_sensitive => false}, :allow_nil => true
  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
  validates :mi_date, :presence => true

  validate do |mi|
    if (mi.mutagenesis_factor.blank? and mi.es_cell.blank?) or (!mi.mutagenesis_factor.blank? and !mi.es_cell.blank?)
      mi.errors.add :base, 'Please Select EITHER an es_cell_name OR mutagenesis_factor'
    end
  end


  # validate mi plan
  validate do |mi_attempt|
    if validate_plan #test whether to continue with validations
      if mi_attempt.mi_plan.phenotype_only
        mi_attempt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (phenotype only)')
      end
      if mi_attempt.mi_plan.mutagenesis_via_crispr_cas9 and !mi_attempt.es_cell.blank?
        mi_attempt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (crispr plan)')
      end

      if !mi_attempt.mi_plan.mutagenesis_via_crispr_cas9 and !mi_attempt.mutagenesis_factor.blank?
        mi_attempt.errors.add(:base, 'MiAttempt cannot be assigned to this MiPlan. (requires crispr plan)')
      end
    end
  end


  validate do |mi_attempt|
    if !mi_attempt.phenotype_attempts.blank? and
              mi_attempt.status != MiAttempt::Status.genotype_confirmed
      mi_attempt.errors.add(:status, 'cannot be changed - phenotype attempts exist')
    end
  end

  validate do |mi|
    if !mi.es_cell.blank? and mi.colonies.length > 1
      mi.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
    end
  end

  # BEGIN Callbacks


  before_validation :set_blank_qc_fields_to_na
  before_validation :set_total_chimeras
  before_validation :set_es_cell_from_es_cell_name

  before_validation :generate_external_ref_if_blank
  before_validation :change_status
  before_validation :manage_colony_for_es_cell_micro_injections_qc_data

  before_validation do |mi|
    return true unless ( ! mi.colony.blank? ) && ( ! mi.colony.colony_qc.blank? ) && mi.colony.colony_qc.qc_loxp_confirmation_changed?
    return true if !mi.allele.blank? and mi.allele.mutation_type.try(:code) == 'cki'

    if mi.qc_loxp_confirmation_result == 'fail'
      self.mouse_allele_type = 'e'
    elsif self.mouse_allele_type == 'e' and (mi.qc_loxp_confirmation_result == 'pass')
      self.mouse_allele_type = nil
    end

    true
  end

  before_validation do |mi|
    if ! mi.external_ref.nil?
      mi.external_ref = mi.external_ref.to_s.strip || mi.external_ref
      mi.external_ref = mi.external_ref.to_s.gsub(/\s+/, ' ')
    end
  end

  before_save :deal_with_unassigned_or_inactive_plans # this method are in belongs_to_mi_plan
  before_save :set_cassette_transmission_verified
  before_save :make_mi_date_and_in_progress_status_consistent
  after_save :add_default_distribution_centre
  after_save :manage_status_stamps
  after_save :reload_mi_plan_mi_attempts

  def colony
    if !es_cell.blank?
      super
    else
      nil
    end
  end

  def colonies
    if !es_cell.blank?
      []
    else
      super
    end
  end

  def set_blank_qc_fields_to_na
    QC_FIELDS.each do |qc_field|
      if self.send("#{qc_field}_result").blank?
        self.send("#{qc_field}_result=", 'na')
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  def set_total_chimeras
    self.total_chimeras = total_male_chimeras.to_i + total_female_chimeras.to_i
  end
  protected :set_total_chimeras

  def set_es_cell_from_es_cell_name
    if ! self.es_cell and !self.es_cell_name.blank?
      self.es_cell = TargRep::EsCell.find_by_name(self.es_cell_name)
    end
  end
  protected :set_es_cell_from_es_cell_name

  def add_default_distribution_centre
    if ['gtc'].include?(self.status.try(:code)) and self.distribution_centres.count == 0
      centre = production_centre_name
      if centre == 'UCD'
        centre = 'KOMP Repo'
      end
      distribution_centre = MiAttempt::DistributionCentre.new({:mi_attempt_id => self.id, :centre_name => centre, :deposited_material_name => 'Live mice'})
      if centre == 'TCP' && consortium_name == 'NorCOMM2'
        distribution_centre.distribution_network = 'CMMR'
      elsif centre == 'TCP' && ['UCD-KOMP', 'DTCC'].include?(consortium_name)
        distribution_centre.centre = Centre.find_by_name('KOMP Repo')
      elsif centre == 'WTSI' and !es_cell.blank? and ['EUCOMM', 'EUCOMMTools'].include?(es_cell.pipeline.try(:name))
        distribution_centre.distribution_network = 'EMMA'
      end
      raise "Could not save DEFAULT distribution Centre" if !distribution_centre.valid?
      distribution_centre.save
    end
  end
  protected :add_default_distribution_centre



  def set_cassette_transmission_verified
    if self.cassette_transmission_verified.blank?
      if self.status_stamps.where("status_id = 2").count != 0
        self.cassette_transmission_verified = self.status_stamps.where("status_id = 2").first.created_at.to_date
        self.cassette_transmission_verified_auto_complete = true
      end
    elsif self.changes.has_key?('cassette_transmission_verified') and !self.changes.has_key?('cassette_transmission_verified_auto_complete')
        self.cassette_transmission_verified_auto_complete = false
    end
    true
  end
  protected :set_cassette_transmission_verified

  def generate_external_ref_if_blank
    return if self.es_cell.blank? && self.mutagenesis_factor.blank?
    return unless self.external_ref.blank?
    return if self.production_centre.blank?
    product_prefix = self.es_cell.nil? ? 'Crisp' : self.es_cell.name
    i = 0
    begin
      i += 1
      self.external_ref = "#{self.production_centre.name}-#{product_prefix}-#{i}"
    end until self.class.find_by_external_ref(self.external_ref).blank?
  end
  protected :generate_external_ref_if_blank


  def manage_colony_for_es_cell_micro_injections_qc_data
    return if es_cell.blank?

    colony_attr_hash = colony.try(:attributes) || {}
    if colony.blank? or (colony.try(:name) != external_ref)
      colony_attr_hash[:name] = external_ref
    end

    if self.status.try(:code) == 'gtc'
      colony_attr_hash[:genotype_confirmed] = true
    elsif self.status.try(:code) != 'gtc'
      colony_attr_hash[:genotype_confirmed] = false
    end

    colony_attr_hash[:id] = colony.id if !colony.blank?
    colony_attr_hash[:colony_qc_attributes] = {} if !colony_attr_hash.has_key?(:colony_qc_attributes)
    colony_attr_hash[:colony_qc_attributes][:id] = colony.colony_qc.id if !colony.blank? and !colony.try(:colony_qc).try(:id).blank?

    QC_FIELDS.each do |qc_field|
      if colony.try(:colony_qc).blank? or self.send("#{qc_field}_result") != colony.colony_qc.send(qc_field)
        colony_attr_hash[:colony_qc_attributes]["#{qc_field}".to_sym] = self.send("#{qc_field}_result")
      end
    end

    self.colony_attributes = colony_attr_hash

  end
  protected :manage_colony_for_es_cell_micro_injections_qc_data

  def make_mi_date_and_in_progress_status_consistent
    in_progress_status = self.status_stamps.find_by_status_id(1)

    if in_progress_status
      if self.mi_date.to_date != in_progress_status.created_at.to_date
        in_progress_status.update_column(:created_at, self.mi_date.to_datetime)
      end
    end
  end
  protected :make_mi_date_and_in_progress_status_consistent

  def reload_mi_plan_mi_attempts
    mi_plan.mi_attempts.reload
  end
  protected :reload_mi_plan_mi_attempts

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

  def distribution_centres_formatted_display
    output_string = ''
    self.distribution_centres.each do |distribution_centre|
      output_array = []
      if distribution_centre.distribution_network
        output_array << distribution_centre.distribution_network
      end
      output_array << distribution_centre.centre.name
      if !distribution_centre.deposited_material.name.nil?
        output_array << distribution_centre.deposited_material.name
      end
      output_string << "[#{output_array.join(', ')}] "
    end
    return output_string.strip
  end

  def mutagenesis_factor_external_ref
    if (self.mutagenesis_factor)
      return self.mutagenesis_factor.external_ref
    else
      return nil
    end
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
    if mouse_allele_type.nil? or es_cell.nil? or es_cell.allele_symbol_superscript_template.nil?
      return nil
    else
      return es_cell.allele_symbol_superscript_template.sub(
        TargRep::EsCell::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_symbol
    if es_cell.blank?
      return nil

    elsif mouse_allele_symbol_superscript
      return "#{es_cell.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"

    else
      return nil
    end
  end

  def allele_symbol
    mi_attempt_allele_symbol_override = mouse_allele_symbol
    if mi_attempt_allele_symbol_override
      return mi_attempt_allele_symbol_override
    else
      return es_cell.allele_symbol unless es_cell.blank?
    end
  end

  def gene
    if mi_plan.try(:gene)
      return mi_plan.gene
    elsif !es_cell.blank? and es_cell.try(:gene)
      return es_cell.gene
    else
      return nil
    end
  end

  def allele
    if !es_cell.blank?
      return es_cell.allele
    end
    return nil
  end

  def mgi_accession_id
    return mi_plan.try(:gene).try(:mgi_accession_id)
  end

  def blast_strain_mgi_accession
    return blast_strain.try(:mgi_strain_accession_id)
  end

  def blast_strain_mgi_name
    return blast_strain.try(:mgi_strain_name)
  end

  def colony_background_strain_mgi_accession
    return colony_background_strain.try(:mgi_strain_accession_id)
  end

  def colony_background_strain_mgi_name
    return colony_background_strain.try(:mgi_strain_name)
  end

  def test_cross_strain_mgi_accession
    return test_cross_strain.try(:mgi_strain_accession_id)
  end

  def test_cross_strain_mgi_name
    return test_cross_strain.try(:mgi_strain_name)
  end

  def es_cell_marker_symbol
    if !es_cell.blank?
      es_cell.try(:marker_symbol)
    else
      nil
    end
  end

  def es_cell_allele_symbol
    if !es_cell.blank?
      es_cell.try(:allele_symbol)
    else
      nil
    end
  end

  def marker_symbol
    if !mi_plan.blank?
      # mi_plan delegates through to gene to fetch marker symbol
      mi_plan.try(:marker_symbol)
    else
      nil
    end
  end

  def mi_plan_mutagenesis_via_crispr_cas9
    if !mi_plan.blank?
      mi_plan.try(:mutagenesis_via_crispr_cas9)
    else
      nil
    end
  end

  def colony_name
    return external_ref
  end

  def colony_name=(arg)
    # Check colony_name has been set/changed. The rest API may return a blank colony_name or a colony_name set to the original value before the external_ref was set to a new value
    return if arg.blank? || (changes.has_key?('external_ref') && changes['external_ref'][0] == arg)
    self.external_ref = arg
  end

  def public_status
    if self.status.code == 'gtc' and self.report_to_public == false
      if !es_cell_id.blank?
        return MiAttempt::Status.find_by_code('chr')
      elsif !mutagensis_factor_id.blank?
        return MiAttempt::Status.find_by_code('fod')
      else
        return MiAttempt::Status.find_by_code('abt')
      end
    end
    return self.status
  end

  delegate :production_centre, :consortium, :to => :mi_plan, :allow_nil => true

  def self.translations
    return {
      'es_cell_marker_symbol'   => 'es_cell_allele_gene_marker_symbol',
      'es_cell_allele_symbol'   => 'es_cell_allele_symbol',
      'consortium_name'         => 'mi_plan_consortium_name',
      'production_centre_name'  => 'mi_plan_production_centre_name',
      'colony_name'             => 'external_ref'
    }
  end

  def in_progress_date
    return status_stamps.all.find {|ss| ss.status_id == MiAttempt::Status.micro_injection_in_progress.id}.created_at.utc.to_date
  end

  def allele_id
    return 0 unless es_cell
    es_cell.allele_id
  end

  def self.readable_name
    return 'micro-injection attempt'
  end

  def relevant_phenotype_attempt_status(cre_required)

    return nil if ! phenotype_attempts || phenotype_attempts.size == 0

    selected_status = {}

    self.phenotype_attempts.each do |phenotype_attempt|

      if cre_required == phenotype_attempt.cre_excision_required

        if selected_status.empty?
          status = phenotype_attempt.status
          selected_status = {
            :name => status.name,
            :order_by => status.order_by,
            :in_progress_date => phenotype_attempt.in_progress_date
          }
        end

        if phenotype_attempt.status.order_by > selected_status[:order_by] or (phenotype_attempt.status.order_by == selected_status[:order_by] and phenotype_attempt.in_progress_date > selected_status[:in_progress_date])
          selected_status = {
            :name => phenotype_attempt.status.name,
            :order_by => phenotype_attempt.status.order_by,
            :in_progress_date => phenotype_attempt.in_progress_date
          }
        end

      end
    end

    selected_status.empty? ? nil : selected_status
  end

end

# == Schema Information
#
# Table name: mi_attempts
#
#  id                                              :integer          not null, primary key
#  es_cell_id                                      :integer
#  mi_date                                         :date             not null
#  status_id                                       :integer          not null
#  external_ref                                    :string(125)
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
#  mouse_allele_type                               :string(3)
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
#  report_to_public                                :boolean          default(TRUE), not null
#  is_active                                       :boolean          default(TRUE), not null
#  is_released_from_genotyping                     :boolean          default(FALSE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer          not null
#  genotyping_comment                              :string(512)
#  legacy_es_cell_id                               :integer
#  qc_lacz_count_qpcr_id                           :integer          default(1)
#  qc_critical_region_qpcr_id                      :integer          default(1)
#  qc_loxp_srpcr_id                                :integer          default(1)
#  qc_loxp_srpcr_and_sequencing_id                 :integer          default(1)
#  cassette_transmission_verified                  :date
#  cassette_transmission_verified_auto_complete    :boolean
#  mutagenesis_factor_id                           :integer
#  crsp_total_embryos_injected                     :integer
#  crsp_total_embryos_survived                     :integer
#  crsp_total_transfered                           :integer
#  crsp_no_founder_pups                            :integer
#  founder_pcr_num_assays                          :integer
#  founder_pcr_num_positive_results                :integer
#  founder_surveyor_num_assays                     :integer
#  founder_surveyor_num_positive_results           :integer
#  founder_t7en1_num_assays                        :integer
#  founder_t7en1_num_positive_results              :integer
#  crsp_total_num_mutant_founders                  :integer
#  crsp_num_founders_selected_for_breading         :integer
#  founder_loa_num_assays                          :integer
#  founder_loa_num_positive_results                :integer
#  allele_id                                       :integer
#  real_allele_id                                  :integer
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (external_ref) UNIQUE
#

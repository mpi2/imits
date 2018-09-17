# encoding: utf-8

class MiAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiAttempt::StatusManagement
  include MiAttempt::WarningGenerator
  include Public::ColonyAttributes
  include ApplicationModel::BelongsToMiPlan

  CRISPR_ASSAY_TYPES = ['PCR', 'Surveyor', 'T7EN1', 'LOA'].freeze
  DELIVERY_METHODS = ['Cytoplasmic Injection', 'Pronuclear Injection', 'Electroporation'].freeze
  TRANSFER_DAY = ['Same Day', 'Next Day'].freeze

  belongs_to :mi_plan
  belongs_to :es_cell, :class_name => 'TargRep::EsCell'
  belongs_to :status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :blast_strain, :class_name => 'Strain'
  belongs_to :test_cross_strain, :class_name => 'Strain'
  belongs_to :mutagenesis_factor, :inverse_of => :mi_attempt, dependent: :destroy
  belongs_to :parent_colony, :class_name => 'Colony'

  has_many   :status_stamps, :order => "#{MiAttempt::StatusStamp.table_name}.created_at ASC", dependent: :destroy, :inverse_of => :mi_attempt
  has_many   :mouse_allele_mods
  has_many   :colonies, inverse_of: :mi_attempt
  has_many   :crisprs, through: :mutagenesis_factor
  has_many   :genotype_primers, through: :mutagenesis_factor
  has_many   :reagents, :class_name => 'Reagent', :inverse_of => :mi_attempt
  has_many   :distribution_centres, :class_name => 'Colony::DistributionCentre', through: :colonies

  access_association_by_attribute :blast_strain, :name
  access_association_by_attribute :test_cross_strain, :name
  access_association_by_attribute :parent_colony, :name

  accepts_nested_attributes_for :status_stamps, :mutagenesis_factor
  accepts_nested_attributes_for :colonies, :allow_destroy => true
  accepts_nested_attributes_for :reagents, :allow_destroy => true

  protected :status=

  validates :status, :presence => true
  validates :external_ref, :presence => true, :uniqueness => {:case_sensitive => false}
  validates :mi_date, :presence => true
  validates :assay_type, :inclusion => { :in => CRISPR_ASSAY_TYPES}, :allow_nil => true

  validate do |mi|
    if (mi.mutagenesis_factor.blank? and mi.es_cell.blank?) or (!mi.mutagenesis_factor.blank? and !mi.es_cell.blank?)
      mi.errors.add :base, 'Please Select EITHER an es_cell_name OR mutagenesis_factor'
    end
  end

  validate do |mi|
    if !mi.crsp_embryo_2_cell.blank? && mi.crsp_embryo_transfer_day != 'Next Day'
      mi.errors.add :crsp_embryo_2_cell, 'Suvival rate of 2 cell stage should only be recorded when the Embryo Survival Day is set to Next Day'
    end
  end

  validate do |mi|
    if (!mi.voltage.blank? || !mi.number_of_pulses.blank?) && mi.delivery_method != 'Electroporation'
      mi.errors.add :delivery_method, 'Voltage and Number of Pulses fields should be used only when the Delivery Method is set to Electroporation'
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


#  validate do |mi_attempt|
#    if !colony.blank? and (!mi_attempt.colony.allele_modifications.blank? or mi_attempt.colony.phenotyping_productions.blank?) and
#              mi_attempt.status != MiAttempt::Status.genotype_confirmed
#      mi_attempt.errors.add(:status, 'cannot be changed - phenotype attempts exist')
#    end
#  end

  validate do |mi|
    if !mi.es_cell.blank? and mi.colonies.length > 1
      mi.errors.add :base, 'Multiple Colonies are not allowed for Mi Attempts micro-injected with an ES Cell clone'
    end
  end

  validate do |mi|
    return if mi.parent_colony.blank?
    if mi.parent_colony.marker_symbol != mi.marker_symbol
      mi.errors.add :base, "The Micro-Injection and the Parent Colony's mutant allele must target/be the same gene."
    end
  end

  # BEGIN Callbacks
  before_validation :set_total_chimeras
  before_validation :set_es_cell_from_es_cell_name
  before_validation :change_status
  before_validation do |mi|
    if ! mi.external_ref.nil?
      mi.external_ref = mi.external_ref.to_s.strip || mi.external_ref
      mi.external_ref = mi.external_ref.to_s.gsub(/\s+/, ' ')
    end
  end


  before_validation :set_colony_from_external_ref

  before_validation do |mi|
    if !self.es_cell_id.blank?

      if self.colonies.count == 1
        if self.status_id == 2
          self.colonies.first.genotype_confirmed = true
        else
          self.colonies.first.genotype_confirmed = false
        end
      end
    end
    return true
  end

  before_save :set_cassette_transmission_verified
  before_save :set_default_background_strain_for_crispr_produced_colonies
  before_save :make_mi_date_and_in_progress_status_consistent
  before_save :crispr_autofill_allele_target
  after_save :manage_status_stamps
  after_save :reload_mi_plan_mi_attempts

  def set_default_background_strain_for_crispr_produced_colonies
    return unless self.blast_strain_id.blank?
    return unless self.es_cell.blank?

    self.blast_strain_name = 'C57BL/6N'
  end
  protected :set_default_background_strain_for_crispr_produced_colonies

  def crispr_autofill_allele_target
    return unless self.es_cell_id.blank? # Only continue if mi_attempt belongs to crispr pipeline

    crispr_count = self.mutagenesis_factor.crisprs.count
    vector_count = self.mutagenesis_factor.donors.count
    vector_type = self.mutagenesis_factor.donors.blank? ? nil : self.mutagenesis_factor.donors.first.vector.try(:allele).try(:type)

    self.allele_target =  nil
    self.allele_target = 'NHEJ' if crispr_count == 1  && vector_count == 0
    self.allele_target = 'Deletion' if crispr_count >= 2 && [mrna_nuclease, protein_nuclease].include?('CAS9') && vector_count == 0
    self.allele_target = 'NHEJ' if crispr_count < 3 && [mrna_nuclease, protein_nuclease].include?('D10A') && vector_count == 0
    self.allele_target = 'Deletion' if crispr_count >= 4 && [mrna_nuclease, protein_nuclease].include?('D10A') && vector_count == 0
    self.allele_target = 'HDR' if vector_count > 0
    self.allele_target = 'HR' if vector_count > 0 && (self.mutagenesis_factor.donors.first.try(:preparation).blank? || self.mutagenesis_factor.donors.first.try(:preparation) != 'Oligo')
    self.allele_target = 'HDR' if vector_count > 0 && vector_type == 'TargRep::HdrAllele'
    self.allele_target = 'HR' if vector_count > 0 && ['TargRep::TargetedAllele', 'TargRep::CrisprTargetedAllele'].include?(vector_type)
    
  end
  protected :crispr_autofill_allele_target

  def reload
    @distribution_centres_attributes = []
    super
  end

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


  def set_colony_from_external_ref
    if self.new_record? && !self.es_cell_name.blank? && !external_ref.blank? && colonies_attributes.blank?
      colony_attr_hash = {}
      colony_attr_hash[:name] = external_ref
      self.colonies_attributes = [colony_attr_hash]
    end
  end
  protected :set_colony_from_external_ref

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

  def mouse_allele_symbol_superscript
    return '' if self.es_cell.blank? || colonies.blank?
    colonies.first.alleles.map{|a| a.mgi_allele_symbol_superscript}.join('')
  end

  def mouse_allele_symbol
    return '' if self.es_cell.blank? || colonies.blank?
    colony_alleles = colonies.first.alleles.map{|a| a.mgi_allele_symbol_superscript}.join('')
    if !colony_alleles.blank?
      return self.marker_symbol + '<sup>' + colony_alleles + '</sup>'
    else
      return []
    end
  end
  def blast_strain_mgi_accession
    return blast_strain.try(:mgi_strain_accession_id)
  end

  def blast_strain_mgi_name
    return blast_strain.try(:mgi_strain_name)
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
      es_cell.alleles[0].try(:allele_symbol)
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

  def public_status
    if self.status.code == 'gtc' and self.report_to_public == false
      if !es_cell_id.blank?
        return MiAttempt::Status.find_by_code('chr')
      elsif !mutagenesis_factor_id.blank?
        return MiAttempt::Status.find_by_code('fod')
      else
        return MiAttempt::Status.find_by_code('abt')
      end
    end
    return self.status
  end

  delegate :production_centre, :consortium, :to => :mi_plan, :allow_nil => true

  def reagents_attributes
    return reagents
  end

  def self.translations
    return {
      'es_cell_marker_symbol'   => 'es_cell_allele_gene_marker_symbol',
      'es_cell_allele_symbol'   => 'es_cell_alleles_allele_symbol',
      'consortium_name'         => 'mi_plan_consortium_name',
      'production_centre_name'  => 'mi_plan_production_centre_name',
      'marker_symbol'           => 'mi_plan_gene_marker_symbol'
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
#  report_to_public                                :boolean          default(TRUE), not null
#  is_active                                       :boolean          default(TRUE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer          not null
#  legacy_es_cell_id                               :integer
#  cassette_transmission_verified                  :date
#  cassette_transmission_verified_auto_complete    :boolean
#  mutagenesis_factor_id                           :integer
#  crsp_total_embryos_injected                     :integer
#  crsp_total_embryos_survived                     :integer
#  crsp_total_transfered                           :integer
#  crsp_no_founder_pups                            :integer
#  crsp_num_founders_selected_for_breading         :integer
#  allele_id                                       :integer
#  founder_num_assays                              :integer
#  assay_type                                      :text
#  experimental                                    :boolean          default(FALSE), not null
#  allele_target                                   :string(255)
#  parent_colony_id                                :integer
#  mrna_nuclease                                   :string(255)
#  mrna_nuclease_concentration                     :float
#  protein_nuclease                                :string(255)
#  protein_nuclease_concentration                  :float
#  delivery_method                                 :string(255)
#  voltage                                         :float
#  number_of_pulses                                :integer
#  crsp_embryo_transfer_day                        :string(255)      default("Same Day")
#  crsp_embryo_2_cell                              :integer
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (external_ref) UNIQUE
#

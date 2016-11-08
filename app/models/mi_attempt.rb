# encoding: utf-8

class MiAttempt < ApplicationModel
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiAttempt::StatusManagement
  include MiAttempt::WarningGenerator
  include ApplicationModel::HasStatuses
  include ApplicationModel::BelongsToMiPlan

  include ::Public::Serializable
  include ::Public::ColonyAttributes

  PRIVATE_ATTRIBUTES = %w{
    allele_symbol
    blast_strain_mgi_accession
    blast_strain_mgi_name
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    es_cell_allele_symbol
    parent_colony_name
    blast_strain_name
    colony_background_strain_name
    test_cross_strain_name
    genotyping_comment
    mrna_nuclease
    mrna_nuclease_concentration
    protein_nuclease
    protein_nuclease_concentration
    delivery_method
    voltage
    number_of_pulses 
  }

  FULL_ACCESS_ATTRIBUTES = %w{
    es_cell_name
    mi_date
    colony_name
    consortium_name
    production_centre_name
    parent_colony_name
    blast_strain_name
    total_blasts_injected
    total_transferred
    number_surrogates_receiving
    total_pups_born
    total_female_chimeras
    total_male_chimeras
    total_chimeras
    number_of_males_with_0_to_39_percent_chimerism
    number_of_males_with_40_to_79_percent_chimerism
    number_of_males_with_80_to_99_percent_chimerism
    number_of_males_with_100_percent_chimerism
    colony_background_strain_name
    test_cross_strain_name
    date_chimeras_mated
    number_of_chimera_matings_attempted
    number_of_chimera_matings_successful
    number_of_chimeras_with_glt_from_cct
    number_of_chimeras_with_glt_from_genotyping
    number_of_chimeras_with_0_to_9_percent_glt
    number_of_chimeras_with_10_to_49_percent_glt
    number_of_chimeras_with_50_to_99_percent_glt
    number_of_chimeras_with_100_percent_glt
    total_f1_mice_from_matings
    number_of_cct_offspring
    number_of_het_offspring
    number_of_live_glt_offspring
    mouse_allele_type
    qc_southern_blot_result
    qc_five_prime_lr_pcr_result
    qc_five_prime_cassette_integrity_result
    qc_tv_backbone_assay_result
    qc_neo_count_qpcr_result
    qc_lacz_count_qpcr_result
    qc_neo_sr_pcr_result
    qc_loa_qpcr_result
    qc_homozygous_loa_sr_pcr_result
    qc_lacz_sr_pcr_result
    qc_mutant_specific_sr_pcr_result
    qc_loxp_confirmation_result
    qc_three_prime_lr_pcr_result
    qc_critical_region_qpcr_result
    qc_loxp_srpcr_result
    qc_loxp_srpcr_and_sequencing_result
    report_to_public
    is_active
    is_released_from_genotyping
    comments
    genotyping_comment
    mi_plan_id
    mutagenesis_factor_id
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    mrna_nuclease
    mrna_nuclease_concentration
    protein_nuclease
    protein_nuclease_concentration
    delivery_method
    voltage
    number_of_pulses 
    crsp_total_embryos_injected
    crsp_total_embryos_survived
    crsp_total_transfered
    crsp_no_founder_pups
    founder_num_assays
    assay_type
    crsp_embryo_transfer_day 
    crsp_embryo_2_cell 
    crsp_num_founders_selected_for_breading
    real_allele_id
    external_ref
    experimental
    distribution_centres_attributes
    colonies_attributes
    reagents_attributes
    mutagenesis_factor_attributes
    g0_screens_attributes
    status_stamps_attributes
    privacy
  }

  READABLE_ATTRIBUTES = %w{
    id
    distribution_centres_formatted_display
    mi_plan_mutagenesis_via_crispr_cas9
    es_cell_marker_symbol
    marker_symbol
    es_cell_allele_symbol
    status_name
    status_dates
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    phenotype_attempts_count
    pipeline_name
    allele_symbol
    blast_strain_mgi_accession
    blast_strain_mgi_name
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    test_cross_strain_mgi_accession
    test_cross_strain_mgi_name
    mgi_accession_id
    mutagenesis_factor_external_ref
    genotyped_confirmed_colony_names
    genotyped_confirmed_colony_phenotype_attempts_count
    genotype_confirmed_allele_symbols
    genotype_confirmed_distribution_centres

  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  def status_name; status.name; end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
  end

  def phenotype_attempts_count
    return 0 if self.colony.blank?
    self.colony.allele_modifications.length + self.colony.phenotyping_productions.length
  end

  def pipeline_name
    try(:es_cell).try(:pipeline).try(:name)
  end

  def genotyped_confirmed_colony_names
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.name}.join(',') + ']'
  end

  def genotyped_confirmed_colony_phenotype_attempts_count
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.phenotype_attempts_count}.join(',') + ']'
  end

  def genotype_confirmed_allele_symbols
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.allele_symbol}.join(',') + ']'
  end

  def genotype_confirmed_distribution_centres
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.distribution_centres.count > 0 ? c.distribution_centres_formatted_display : '[]'}.join(',') + ']'

  end

  def mutagenesis_factor_attributes
    json_options = {
    :methods => ['crisprs_attributes', 'vectors_attributes', 'genotype_primers_attributes']
    }
    return mutagenesis_factor.as_json(json_options)
  end

  def g0_screens_attributes
    json_options = {
    :only => ['no_g0_where_mutation_detected', 'no_nhej_g0_mutants', 'no_deletion_g0_mutants', 'no_hr_g0_mutants',
              'no_hdr_g0_mutants', 'no_hdr_g0_mutants_all_donors_inserted', 'no_hdr_g0_mutants_subset_donors_inserted'],
    :methods => ['marker_symbol']
    }
    mutagenesis_factor.as_json(json_options)
  end







  CRISPR_ASSAY_TYPES = ['PCR', 'Surveyor', 'T7EN1', 'LOA'].freeze
  DELIVERY_METHODS = ['Cytoplasmic Injection', 'Pronuclear Injection', 'Electroporation'].freeze
  TRANSFER_DAY = ['Same Day', 'Next Day'].freeze
  PRIVACY_OPTIONS = ['Keep Allele(s) private', 'Only Share Deletion & NHEJ Allele(s)', 'Share all Allele(s)'].freeze

  belongs_to :real_allele
  belongs_to :mi_plan
  belongs_to :es_cell, :class_name => 'TargRep::EsCell'
  belongs_to :status
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :blast_strain, :class_name => 'Strain'
  belongs_to :test_cross_strain, :class_name => 'Strain'
  belongs_to :mutagenesis_factor, :inverse_of => :mi_attempt, dependent: :destroy
  belongs_to :parent_colony, :class_name => 'Colony'

  has_one    :colony, inverse_of: :mi_attempt, dependent: :destroy

  has_many   :status_stamps, :order => "#{MiAttempt::StatusStamp.table_name}.created_at ASC", dependent: :destroy
  has_many   :mouse_allele_mods
  has_many   :colonies, inverse_of: :mi_attempt
  has_many   :crisprs, through: :mutagenesis_factor
  has_many   :genotype_primers, through: :mutagenesis_factor
  has_many   :reagents, :class_name => 'Reagent'

  access_association_by_attribute :blast_strain, :name
  access_association_by_attribute :test_cross_strain, :name
  access_association_by_attribute :parent_colony, :name

  ColonyQc::QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'

    define_method("#{qc_field}_result=") do |arg|
      instance_variable_set("@#{qc_field}_result",arg)
    end

    define_method("#{qc_field}_result") do
      return nil if es_cell.blank?
      if !instance_variable_get("@#{qc_field}_result").blank?
        return instance_variable_get("@#{qc_field}_result")
      elsif !colony.blank? and !colony.try(:colony_qc).try(qc_field.to_sym).blank?
        return colony.colony_qc.send(qc_field)
      else
        return 'na'
      end
    end
  end

  accepts_nested_attributes_for :status_stamps, :mutagenesis_factor
  accepts_nested_attributes_for :colony, :update_only =>true
  accepts_nested_attributes_for :colonies, :allow_destroy => true
  accepts_nested_attributes_for :reagents, :allow_destroy => true

  protected :status=

  validates :status, :presence => true
  validates :external_ref, :uniqueness => {:case_sensitive => false}, :allow_nil => true
#  validates :mouse_allele_type, :inclusion => { :in => MOUSE_ALLELE_OPTIONS.keys }
  validates :mi_date, :presence => true
  validates :assay_type, :inclusion => { :in => CRISPR_ASSAY_TYPES}, :allow_nil => true
  validates :privacy, :inclusion => { :in => PRIVACY_OPTIONS}, :allow_nil => false


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


  before_validation :set_blank_qc_fields_to_na
  before_validation :set_total_chimeras
  before_validation :set_es_cell_from_es_cell_name

  before_validation :generate_external_ref_if_blank
  before_validation :change_status
  before_validation :manage_colony_for_es_cell_micro_injections_qc_data
  before_validation :set_privacy_settings

  before_validation do |mi|
    return true unless ( ! mi.colony.blank? ) && ( ! mi.colony.colony_qc.blank? ) && mi.colony.colony_qc.qc_loxp_confirmation_changed?
    return true if !mi.allele.blank? and mi.allele.mutation_type.try(:code) == 'cki'

    if mi.qc_loxp_confirmation_result == 'fail' && mi.allele.mutation_type.try(:allele_code) == 'a'
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
    vector_count = self.mutagenesis_factor.vectors.count
    vector_type = self.mutagenesis_factor.vectors.blank? ? nil : self.mutagenesis_factor.vectors.first.vector.try(:allele).try(:type)

    self.allele_target =  nil
    self.allele_target = 'NHEJ' if crispr_count == 1  && vector_count == 0
    self.allele_target = 'Deletion' if crispr_count >= 2 && [mrna_nuclease, protein_nuclease].include?('CAS9') && vector_count == 0
    self.allele_target = 'NHEJ' if crispr_count < 3 && [mrna_nuclease, protein_nuclease].include?('D10A') && vector_count == 0
    self.allele_target = 'Deletion' if crispr_count >= 4 && [mrna_nuclease, protein_nuclease].include?('D10A') && vector_count == 0
    self.allele_target = 'HDR' if vector_count > 0
    self.allele_target = 'HR' if vector_count > 0 && (self.mutagenesis_factor.vectors.first.try(:preparation).blank? || self.mutagenesis_factor.vectors.first.try(:preparation) != 'Oligo')
    self.allele_target = 'HDR' if vector_count > 0 && vector_type == 'TargRep::HdrAllele'
    self.allele_target = 'HR' if vector_count > 0 && ['TargRep::TargetedAllele', 'TargRep::CrisprTargetedAllele'].include?(vector_type)
    
  end
  protected :crispr_autofill_allele_target

  def reload
    @distribution_centres_attributes = []
    super
  end

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

  def distribution_centres_attributes
    return nil if es_cell.blank?
    return @distribution_centres_attributes unless @distribution_centres_attributes.blank?
    return distribution_centres.map(&:as_json) unless distribution_centres.blank?
    return nil
  end

  def distribution_centres_attributes=(arg)
    @distribution_centres_attributes = arg
  end

  def distribution_centres
    return [] if es_cell.blank?
    colony.try(:distribution_centres)
  end

  def set_blank_qc_fields_to_na
    ColonyQc::QC_FIELDS.each do |qc_field|
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

    if self.colony_background_strain_name != colony.try(:background_strain_name)
      colony_attr_hash[:background_strain_name] = self.colony_background_strain_name
    end

    if self.mouse_allele_type != colony.try(:allele_type)
      colony_attr_hash[:allele_type] = self.mouse_allele_type
    end

    colony_attr_hash[:distribution_centres_attributes] = self.distribution_centres_attributes unless self.distribution_centres_attributes.blank?

    colony_attr_hash[:colony_qc_attributes] = {} if !colony_attr_hash.has_key?(:colony_qc_attributes)

    ColonyQc::QC_FIELDS.each do |qc_field|
      if colony.try(:colony_qc).blank? or self.send("#{qc_field}_result") != colony.colony_qc.send(qc_field)
        colony_attr_hash[:colony_qc_attributes]["#{qc_field}".to_sym] = self.send("#{qc_field}_result")
      end
    end
    self.colony_attributes = colony_attr_hash
  end
  protected :manage_colony_for_es_cell_micro_injections_qc_data


  def set_privacy_settings
    return unless PRIVACY_OPTIONS.include?(privacy)
    case privacy
    when "Keep Allele(s) private"
        mutagenesis_factor.private = true if !mutagenesis_factor_id.blank?
        colony.private = true if !colony.blank?
        colonies.each{|c| c.private = true} if !colonies.blank?

    when "Only Share Deletion & NHEJ Allele(s)"
        mutagenesis_factor.private = true if !mutagenesis_factor_id.blank?
        colony.private = true if !colony.blank?
        if !colonies.blank?
          colonies.each do |c|
            next if c.crispr_allele_category.blank?
            if ['NHEJ', 'Deletion'].include?(c.crispr_allele_category)
              c.private = false
            else 
              c.private = true
            end
          end 
        end

    when "Share all Allele(s)"
        mutagenesis_factor.private = false if !mutagenesis_factor_id.blank?
        colony.private = false if !colony.blank?
        colonies.each{|c| c.private = false} if !colonies.blank?
        
    end
  end
  private :set_privacy_settings


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
    return nil unless colony
    return colony.allele_symbol_superscript
  end

  def mouse_allele_symbol
    return nil unless colony
    return colony.allele_symbol
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

  def mouse_allele_type=(arg)
    @mouse_allele_type = arg unless es_cell.nil?
  end

  def mouse_allele_type
    return @mouse_allele_type if defined? @mouse_allele_type
    return colony.allele_type unless es_cell.blank? || colony.blank?
  end

  def colony_background_strain
    colony.try(:background_strain)
  end

  def colony_background_strain_name
    return @colony_background_strain_name unless @colony_background_strain_name.blank?
    return colony.background_strain.try(:name) unless es_cell.blank? || colony.blank?
    return nil
  end

  def colony_background_strain_name=(arg)
    @colony_background_strain_name = arg unless es_cell.blank?
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
      'es_cell_allele_symbol'   => 'es_cell_allele_symbol',
      'consortium_name'         => 'mi_plan_consortium_name',
      'production_centre_name'  => 'mi_plan_production_centre_name'
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
#  is_released_from_genotyping                     :boolean          default(FALSE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer          not null
#  genotyping_comment                              :string(512)
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
#  real_allele_id                                  :integer
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
#  privacy                                         :string(255)      default("Share all Allele(s)"), not null
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (external_ref) UNIQUE
#

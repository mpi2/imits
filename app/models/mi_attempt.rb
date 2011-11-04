# encoding: utf-8

class MiAttempt < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  extend AccessAssociationByAttribute
  include MiAttempt::StatusChanger
  include MiAttempt::WarningGenerator

  EMMA_OPTIONS = {
    'unsuitable' => 'Unsuitable for EMMA',
    'suitable' => 'Suitable for EMMA',
    'suitable_sticky' => 'Suitable for EMMA - STICKY',
    'unsuitable_sticky' => 'Unsuitable for EMMA - STICKY',
  }.freeze

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

  MOUSE_ALLELE_OPTIONS = {
    nil => '[none]',
    'a' => 'a - Knockout-first - Reporter Tagged Insertion',
    'b' => 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion',
    'c' => 'c - Knockout-First, Post-Flp - Conditional',
    'd' => 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter',
    'e' => 'e - Targeted Non-Conditional'
  }.freeze

  PRIVATE_ATTRIBUTES = [
    'created_at', 'updated_at', 'updated_by', 'updated_by_id',
    'mi_attempt_status', 'mi_attempt_status_id',
    'es_cell', 'es_cell_id', 'mi_plan_id', 'mi_plan'
  ]

  attr_protected *PRIVATE_ATTRIBUTES

  belongs_to :mi_plan
  belongs_to :es_cell
  belongs_to :mi_attempt_status
  belongs_to :distribution_centre, :class_name => 'Centre'
  belongs_to :updated_by, :class_name => 'User'
  belongs_to :blast_strain, :class_name => 'Strain::BlastStrain'
  belongs_to :colony_background_strain, :class_name => 'Strain::ColonyBackgroundStrain'
  belongs_to :test_cross_strain, :class_name => 'Strain::TestCrossStrain'
  belongs_to :deposited_material
  has_many :status_stamps, :order => "#{MiAttempt::StatusStamp.table_name}.created_at ASC"

  access_association_by_attribute :distribution_centre, :name
  access_association_by_attribute :blast_strain, :name
  access_association_by_attribute :colony_background_strain, :name
  access_association_by_attribute :test_cross_strain, :name
  access_association_by_attribute :deposited_material, :name

  QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'
    access_association_by_attribute qc_field, :description, :attribute_alias => :result
  end

  validates :es_cell_name, :presence => true
  validates :production_centre_name, :presence => true
  validates :consortium_name, :presence => true
  validates :mi_attempt_status, :presence => true
  validates :colony_name, :uniqueness => true, :allow_nil => true
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
              matching_mi_plan.mi_plan_status == MiPlanStatus['Aborted - ES Cell QC Failed']
      error = 'ES cells failed QC'
      mi.errors.add :base, error
    end
  end

  validates_each :consortium_name, :production_centre_name do |mi, attr, value|
    next if value.blank?
    association_name = attr.to_s.gsub('_name', '')
    klass = {:consortium_name => Consortium, :production_centre_name => Centre}[attr]

    if mi.mi_plan and mi.mi_plan.send(association_name) and value != mi.mi_plan.send(association_name).name
      mi.errors.add attr, 'cannot be modified'
    else
      associated = klass.find_by_name(value)
      if associated.blank?
        mi.errors.add attr, 'does not exist'
      end
    end
  end

  validate do |mi_attempt|
    next unless mi_attempt.es_cell and mi_attempt.mi_plan and mi_attempt.es_cell.gene and mi_attempt.mi_plan.gene
    if(mi_attempt.es_cell.gene != mi_attempt.mi_plan.gene)
      mi_attempt.errors.add :base, "mi_plan and es_cell gene mismatch!  Should be the same! (#{mi_attempt.es_cell.gene.marker_symbol} != #{mi_attempt.mi_plan.gene.marker_symbol})"
    end
  end

  before_validation :set_blank_qc_fields_to_na
  before_validation :set_blank_strings_to_nil
  before_validation :set_total_chimeras
  before_validation :set_default_deposited_material
  before_validation :set_es_cell_from_es_cell_name
  before_validation :set_default_distribution_centre
  before_validation :change_status

  before_save :generate_colony_name_if_blank
  before_save :make_unsuitable_for_emma_if_is_not_active
  before_save :set_mi_plan
  before_save :record_if_status_was_changed

  after_save :create_status_stamp_if_status_was_changed

  def self.active
    where(:is_active => true)
  end

  def self.genotype_confirmed
    where(:mi_attempt_status_id => MiAttemptStatus.genotype_confirmed.id)
  end

  def self.in_progress
    where(:mi_attempt_status_id => MiAttemptStatus.micro_injection_in_progress.id)
  end

  def self.aborted
    where(:mi_attempt_status_id => MiAttemptStatus.micro_injection_aborted.id)
  end

  # BEGIN Callbacks

  protected

  def set_total_chimeras
    self.total_chimeras = total_male_chimeras.to_i + total_female_chimeras.to_i
  end

  def set_blank_strings_to_nil
    self.attributes.each do |name, value|
      if self[name].respond_to?(:to_str) && self[name].blank?
        self[name] = nil
      end
    end
  end

  def set_es_cell_from_es_cell_name
    if ! self.es_cell
      self.es_cell = EsCell.find_or_create_from_marts_by_name(self.es_cell_name)
    end
  end

  def set_default_distribution_centre
    self.distribution_centre ||= Centre.find_by_name(self.production_centre_name)
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

  def set_default_deposited_material
    if self.deposited_material.nil?
      self.deposited_material = DepositedMaterial.find_by_name!('Frozen embryos')
      self.deposited_material_name = self.deposited_material.name
    end
  end

  def make_unsuitable_for_emma_if_is_not_active
    if ! self.is_active?
      self.is_suitable_for_emma = false
    end
    return true
  end

  def set_mi_plan
    if new_record?
      mi_plan_to_set = find_matching_mi_plan
      if ! mi_plan_to_set
        mi_plan_to_set = MiPlan.new(:priority => 'High')
        mi_plan_to_set.consortium_name = consortium_name
        mi_plan_to_set.gene = es_cell.gene
      end

      mi_plan_to_set.production_centre_name = production_centre_name
      mi_plan_to_set.mi_plan_status = MiPlanStatus.find_by_name!('Assigned')
      mi_plan_to_set.save!

      self.mi_plan = mi_plan_to_set
    else
      if is_active?
        mi_plan.mi_plan_status = MiPlanStatus.find_by_name!('Assigned')
        mi_plan.save!
      end
    end
  end

  def record_if_status_was_changed
    if self.changed.include? 'mi_attempt_status_id'
      @new_mi_attempt_status = self.mi_attempt_status
    else
      @new_mi_attempt_status = nil
    end
  end

  def create_status_stamp_if_status_was_changed
    if @new_mi_attempt_status
      add_status_stamp @new_mi_attempt_status
    end
  end

  public

  # END Callbacks

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

  def status
    return self.mi_attempt_status.try(:description)
  end

  def add_status_stamp(new_status)
    self.status_stamps.create!(:mi_attempt_status => new_status)
    self.status_stamps.reload
  end
  private :add_status_stamp

  def emma_status
    if is_suitable_for_emma?
      if is_emma_sticky? then return 'suitable_sticky' else return 'suitable' end
    else
      if is_emma_sticky? then return 'unsuitable_sticky' else return 'unsuitable' end
    end
  end

  class EmmaStatusError < RuntimeError; end

  def emma_status=(status)
    case status.to_s
    when 'suitable' then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = false

    when 'unsuitable' then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = false

    when 'suitable_sticky' then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = true

    when 'unsuitable_sticky' then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = true

    else
      raise EmmaStatusError, "Invalid status '#{status.inspect}'"
    end
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
    if mouse_allele_type.nil?
      return nil
    else
      return "#{es_cell.marker_symbol}<sup>#{mouse_allele_symbol_superscript}</sup>"
    end
  end

  delegate :gene, :to => :es_cell

  def es_cell_marker_symbol; es_cell.try(:marker_symbol); end
  def es_cell_allele_symbol; es_cell.try(:allele_symbol); end

  def find_matching_mi_plan
    consortium = Consortium.find_by_name(consortium_name)
    production_centre = Centre.find_by_name(production_centre_name)
    return unless es_cell and consortium and production_centre
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

  def self.translate_search_param(param)
    translations = {
      'es_cell_marker_symbol'   => 'es_cell_gene_marker_symbol',
      'es_cell_allele_symbol'   => 'es_cell_gene_allele_symbol',
      'consortium_name'         => 'mi_plan_consortium_name',
      'production_centre_name'  => 'mi_plan_production_centre_name',
      'status'                  => 'mi_attempt_status_description'
    }

    translations.each do |tr_from, tr_to|
      md = /^#{tr_from}_(.+)$/.match(param)
      if md
        return "#{tr_to}_#{md[1]}"
      end
    end

    return param
  end

  def self.public_search(params)
    translated_params = {}
    params.stringify_keys.each do |name, value|
      translated_params[translate_search_param(name)] = value
    end
    return self.search(translated_params)
  end

  def as_json(options = {})
    json = super(default_serializer_options(options))
    json['mi_date'] = self.mi_date.to_s
    json
  end

  def to_xml(options = {})
    super(default_serializer_options(options))
  end

  private

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] ||= [
      'es_cell_name', 'emma_status', 'status',
      'blast_strain_name', 'colony_background_strain_name', 'test_cross_strain_name',
      'distribution_centre_name', 'production_centre_name', 'consortium_name',
      'mouse_allele_symbol_superscript', 'deposited_material_name',
      'es_cell_marker_symbol', 'es_cell_allele_symbol'
    ] + QC_FIELDS.map{|i| "#{i}_result"}
    options[:except] ||= PRIVATE_ATTRIBUTES.dup + QC_FIELDS.map{|i| "#{i}_id"} + [
      'blast_strain_id', 'colony_background_strain_id', 'test_cross_strain_id',
      'distribution_centre_id', 'deposited_material_id'
    ]
    return options
  end

end

# == Schema Information
#
# Table name: mi_attempts
#
#  id                                              :integer         not null, primary key
#  es_cell_id                                      :integer         not null
#  mi_date                                         :date            not null
#  mi_attempt_status_id                            :integer         not null
#  colony_name                                     :string(125)
#  distribution_centre_id                          :integer
#  updated_by_id                                   :integer
#  deposited_material_id                           :integer         not null
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
#  is_suitable_for_emma                            :boolean         default(FALSE), not null
#  is_emma_sticky                                  :boolean         default(FALSE), not null
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
#  mouse_allele_type                               :string(1)
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
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (colony_name) UNIQUE
#


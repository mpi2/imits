# encoding: utf-8

class MiAttempt < ActiveRecord::Base
  acts_as_reportable

  extend AccessAssociationByAttribute

  EMMA_OPTIONS = {
    :unsuitable => 'Unsuitable for EMMA',
    :suitable => 'Suitable for EMMA',
    :suitable_sticky => 'Suitable for EMMA - STICKY',
    :unsuitable_sticky => 'Unsuitable for EMMA - STICKY',
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

  MOUSE_ALLELE_OPTIONS = [
    [nil, '[none]'],
    ['a', 'a - Knockout-first - Reporter Tagged Insertion'],
    ['b', 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion'],
    ['c', 'c - Knockout-First, Post-Flp - Conditional'],
    ['d', 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter'],
    ['e', 'e - Targeted Non-Conditional']
  ].freeze

  PRIVATE_ATTRIBUTES = [
    :created_at, :updated_at, :updated_by, :updated_by_id, :clone,
    :clone_id, :mi_attempt_status, :mi_attempt_status_id
  ] +QC_FIELDS.map {|i| "#{i}_id"}

  attr_protected *PRIVATE_ATTRIBUTES

  acts_as_audited

  belongs_to :clone

  def clone_name
    if(self.clone)
      self.clone.clone_name
    else
      @clone_name
    end
  end

  def clone_name=(arg)
    if(! self.clone)
      @clone_name = arg
    end
  end

  validates :clone_name, :presence => true

  validates_each :clone_name do |record, attr, value|
    if !record.clone_name.blank? and record.clone.blank?
      record.errors.add :clone_name, 'was not found in the marts'
    end
  end

  belongs_to :mi_attempt_status
  validates :mi_attempt_status, :presence => true

  # TODO validates :colony_name, :uniqueness => true, :allow_nil => true

  belongs_to :production_centre, :class_name => 'Centre'
  validates :production_centre, :presence => true
  belongs_to :distribution_centre, :class_name => 'Centre'

  belongs_to :updated_by, :class_name => 'User'

  belongs_to :blast_strain, :class_name => 'Strain::BlastStrain'
  access_association_by_attribute :blast_strain, :name

  belongs_to :colony_background_strain, :class_name => 'Strain::ColonyBackgroundStrain'
  access_association_by_attribute :colony_background_strain, :name

  belongs_to :test_cross_strain, :class_name => 'Strain::TestCrossStrain'
  access_association_by_attribute :test_cross_strain, :name

  QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcResult'
  end

  before_validation :set_default_status
  before_validation :set_total_chimeras
  before_validation :set_blank_strings_to_nil
  before_validation :set_clone_from_clone_name
  before_validation :set_default_distribution_centre

  before_save :save_qc_fields

  protected

  def set_default_status
    self.mi_attempt_status ||= MiAttemptStatus.micro_injection_in_progress
  end

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

  def set_clone_from_clone_name
    if ! self.clone
      self.clone = Clone.find_or_create_from_mart_by_clone_name(self.clone_name)
    end
  end

  def set_default_distribution_centre
    self.distribution_centre ||= self.production_centre
  end

  public

  def emma_status
    if is_suitable_for_emma?
      if is_emma_sticky? then return :suitable_sticky else return :suitable end
    else
      if is_emma_sticky? then return :unsuitable_sticky else return :unsuitable end
    end
  end

  class EmmaStatusError < RuntimeError; end

  def emma_status=(status)
    case status.to_sym
    when :suitable then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = false

    when :unsuitable then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = false

    when :suitable_sticky then
      self.is_suitable_for_emma = true
      self.is_emma_sticky = true

    when :unsuitable_sticky then
      self.is_suitable_for_emma = false
      self.is_emma_sticky = true

    else
      raise EmmaStatusError, "Invalid status '#{status.inspect}'"
    end
  end

  def mouse_allele_name_superscript
    if mouse_allele_type.nil?
      return nil
    else
      return clone.allele_name_superscript_template.sub(
        Clone::TEMPLATE_CHARACTER, mouse_allele_type)
    end
  end

  def mouse_allele_name
    if mouse_allele_type.nil?
      return nil
    else
      return "#{clone.marker_symbol}<sup>#{mouse_allele_name_superscript}</sup>"
    end
  end

  # == BEGIN #qc virtual attribute

  validates_each :qc do |record, attr, value|
    acceptable_results = QcResult.all.map(&:description)
    error_messages = []
    record.qc.each_pair do |short_qc_field, result|
      next unless result

      unless acceptable_results.include? result
        error_messages << "#{short_qc_field} => '#{result}'"
      end
    end

    unless error_messages.blank?
      record.errors[:qc] = "Erroneous QC fields: #{error_messages.join ', '}"
    end
  end

  def qc
    if @qc.blank?
      @qc = {}

      QC_FIELDS.each do |qc_field|
        @qc[qc_field.to_s.gsub(/^qc_/, '')] = self.send(qc_field).try(:description)
      end
    end

    return @qc
  end

  def qc=(args)
    raise ArgumentError, "Expected hash, got #{args.class}" unless args.is_a? Hash
    args = args.stringify_keys
    self.qc.keys.each do |short_qc_field|
      if args.include? short_qc_field
        @qc[short_qc_field] = args[short_qc_field]
      end
    end
  end

  def save_qc_fields
    return if @qc.blank?

    @qc.each do |short_qc_field, result|
      next unless QC_FIELDS.include?( ('qc_' + short_qc_field).to_sym )
      result_model = QcResult.find_by_description(result)
      self.send "qc_#{short_qc_field}=", result_model
    end
  end
  protected :save_qc_fields

  # == END #qc virtual attribute

  def self.search(*args, &block)
    return non_metasearch_search(*args, &block)
  end

  scope :non_metasearch_search, proc { |params|
    terms, production_centre_id, mi_attempt_status_id = params.symbolize_keys.values_at(
      :search_terms, :production_centre_id, :mi_attempt_status_id)

    terms ||= []
    terms = terms.dup.delete_if {|i| i.strip.empty?}
    terms.map(&:upcase!)

    sql_texts = []
    sql_params = []

    unless terms.blank?
      sql_texts <<
              '(UPPER(clones.clone_name) IN (?) OR ' +
              ' UPPER(clones.marker_symbol) IN (?) OR ' +
              ' UPPER(mi_attempts.colony_name) IN (?))'
      sql_params << terms  << terms << terms
    end

    unless production_centre_id.blank?
      sql_texts << 'mi_attempts.production_centre_id = ?'
      sql_params << production_centre_id
    end

    unless mi_attempt_status_id.blank?
      sql_texts << 'mi_attempts.mi_attempt_status_id = ?'
      sql_params << mi_attempt_status_id
    end

    if sql_texts.blank?
      scoped
    else
      sql_text = sql_texts.join(' AND ')
      joins(:clone).where(sql_text, *sql_params)
    end
  }

  def default_serializer_options(options = {})
    options ||= {}
    options.symbolize_keys!
    options[:methods] ||= [:qc, :clone_name]
    options[:except] ||= PRIVATE_ATTRIBUTES.dup
    return options
  end
  private :default_serializer_options

  def as_json(options = {})
    super(default_serializer_options(options))
  end

  def to_xml(options = {})
    super(default_serializer_options(options))
  end

end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: mi_attempts
#
#  id                                              :integer         not null, primary key
#  clone_id                                        :integer         not null
#  mi_date                                         :date
#  mi_attempt_status_id                            :integer         not null
#  colony_name                                     :text
#  production_centre_id                            :integer         not null
#  distribution_centre_id                          :integer
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
#  mouse_allele_type                               :text
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
#  should_export_to_mart                           :boolean         default(TRUE), not null
#  is_active                                       :boolean         default(TRUE), not null
#  is_released_from_genotyping                     :boolean         default(FALSE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#

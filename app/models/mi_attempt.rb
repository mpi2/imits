# encoding: utf-8

class MiAttempt < ActiveRecord::Base

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

  acts_as_audited :protect => false

  belongs_to :clone
  validates :clone, :presence => true

  belongs_to :mi_attempt_status
  validates :mi_attempt_status, :presence => true

  belongs_to :production_centre, :class_name => 'Centre'
  belongs_to :distribution_centre, :class_name => 'Centre'
  belongs_to :updated_by, :class_name => 'User'

  belongs_to :blast_strain, :class_name => 'Strain::BlastStrain'
  belongs_to :colony_background_strain, :class_name => 'Strain::ColonyBackgroundStrain'
  belongs_to :test_cross_strain, :class_name => 'Strain::TestCrossStrain'

  QC_FIELDS.each do |qc_field|
    belongs_to qc_field, :class_name => 'QcStatus'
  end

  before_validation :set_default_status
  before_validation :set_total_chimeras
  before_validation :set_blank_strings_to_nil

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

  scope :search, proc { |params|
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
end



# == Schema Information
# Schema version: 20110421150000
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
#  created_at                                      :datetime
#  updated_at                                      :datetime
#


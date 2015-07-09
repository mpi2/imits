class ColonyQc < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

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

  belongs_to :colony

  validates :colony, :presence => true

  possible_qc_values = ['na', 'pass', 'fail']
  QC_FIELDS.each do |qc_field|
    validates qc_field, :inclusion => { :in => possible_qc_values }
  end

  before_validation :set_blank_qc_fields_to_na

  def set_blank_qc_fields_to_na
    QC_FIELDS.each do |qc_field|
      if self.send(qc_field).blank?
        self.send("#{qc_field}=", 'na')
      end
    end
  end
  protected :set_blank_qc_fields_to_na

  def self.readable_name
    return 'colony_qc'
  end

end

# == Schema Information
#
# Table name: colony_qcs
#
#  id                               :integer          not null, primary key
#  qc_southern_blot                 :string(255)      not null
#  qc_five_prime_lr_pcr             :string(255)      not null
#  qc_five_prime_cassette_integrity :string(255)      not null
#  qc_tv_backbone_assay             :string(255)      not null
#  qc_neo_count_qpcr                :string(255)      not null
#  qc_lacz_count_qpcr               :string(255)      not null
#  qc_neo_sr_pcr                    :string(255)      not null
#  qc_loa_qpcr                      :string(255)      not null
#  qc_homozygous_loa_sr_pcr         :string(255)      not null
#  qc_lacz_sr_pcr                   :string(255)      not null
#  qc_mutant_specific_sr_pcr        :string(255)      not null
#  qc_loxp_confirmation             :string(255)      not null
#  qc_three_prime_lr_pcr            :string(255)      not null
#  qc_critical_region_qpcr          :string(255)      not null
#  qc_loxp_srpcr                    :string(255)      not null
#  qc_loxp_srpcr_and_sequencing     :string(255)      not null
#  colony_allele_id                 :integer
#

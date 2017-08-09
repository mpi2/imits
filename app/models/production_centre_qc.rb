class ProductionCentreQc < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :allele

  QC_FIELDS = [
    :southern_blot,
    :five_prime_lr_pcr,
    :five_prime_cassette_integrity,
    :tv_backbone_assay,
    :neo_count_qpcr,
    :lacz_count_qpcr,
    :neo_sr_pcr,
    :loa_qpcr,
    :homozygous_loa_sr_pcr,
    :lacz_sr_pcr,
    :mutant_specific_sr_pcr,
    :loxp_confirmation,
    :three_prime_lr_pcr,
    :critical_region_qpcr,
    :loxp_srpcr,
    :loxp_srpcr_and_sequencing
  ].freeze

  belongs_to :allele

  validates :allele, :presence => true

  possible_qc_values = ['na', 'pass', 'fail', 'no reads detected']
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
    return 'production_centre_qcs'
  end

end

# == Schema Information
#
# Table name: production_centre_qcs
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
#  allele_id                        :integer
#

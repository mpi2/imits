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

  validates :colony_id, :presence => true, :uniqueness => true

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

  # ##
  # # public getter and setter accessors for backwards compatability
  # ##

  # # qc_southern_blot_result
  # def qc_southern_blot_result
  #   if(self.qc_southern_blot)
  #     return self.qc_southern_blot
  #   else
  #     return @qc_southern_blot
  #   end
  # end

  # def qc_southern_blot_result=(arg)
  #   if(! self.qc_southern_blot)
  #     @qc_southern_blot = arg
  #   end
  # end

  # # qc_five_prime_lr_pcr_result
  # def qc_five_prime_lr_pcr_result
  #   if(self.qc_five_prime_lr_pcr)
  #     return self.qc_five_prime_lr_pcr
  #   else
  #     return @qc_five_prime_lr_pcr
  #   end
  # end

  # def qc_five_prime_lr_pcr_result=(arg)
  #   if(! self.qc_five_prime_lr_pcr)
  #     @qc_five_prime_lr_pcr = arg
  #   end
  # end

  # # qc_five_prime_cassette_integrity
  # def qc_five_prime_cassette_integrity_result
  #   if(self.qc_five_prime_cassette_integrity)
  #     return self.qc_five_prime_cassette_integrity
  #   else
  #     return @qc_five_prime_cassette_integrity
  #   end
  # end

  # def qc_five_prime_cassette_integrity_result=(arg)
  #   if(! self.qc_five_prime_cassette_integrity)
  #     @qc_five_prime_cassette_integrity = arg
  #   end
  # end

  # # qc_tv_backbone_assay
  # def qc_tv_backbone_assay_result
  #   if(self.qc_tv_backbone_assay)
  #     return self.qc_tv_backbone_assay
  #   else
  #     return @qc_tv_backbone_assay
  #   end
  # end

  # def qc_tv_backbone_assay_result=(arg)
  #   if(! self.qc_tv_backbone_assay)
  #     @qc_tv_backbone_assay = arg
  #   end
  # end

  # # qc_neo_count_qpcr
  # def qc_neo_count_qpcr_result
  #   if(self.qc_neo_count_qpcr)
  #     return self.qc_neo_count_qpcr
  #   else
  #     return @qc_neo_count_qpcr
  #   end
  # end

  # def qc_neo_count_qpcr_result=(arg)
  #   if(! self.qc_neo_count_qpcr)
  #     @qc_neo_count_qpcr = arg
  #   end
  # end

  # # qc_lacz_count_qpcr
  # def qc_lacz_count_qpcr_result
  #   if(self.qc_lacz_count_qpcr)
  #     return self.qc_lacz_count_qpcr
  #   else
  #     return @qc_lacz_count_qpcr
  #   end
  # end

  # def qc_lacz_count_qpcr_result=(arg)
  #   if(! self.qc_lacz_count_qpcr)
  #     @qc_lacz_count_qpcr = arg
  #   end
  # end

  # # qc_neo_sr_pcr
  # def qc_neo_sr_pcr_result
  #   if(self.qc_neo_sr_pcr)
  #     return self.qc_neo_sr_pcr
  #   else
  #     return @qc_neo_sr_pcr
  #   end
  # end

  # def qc_neo_sr_pcr_result=(arg)
  #   if(! self.qc_neo_sr_pcr)
  #     @qc_neo_sr_pcr = arg
  #   end
  # end

  # # qc_loa_qpcr
  # def qc_loa_qpcr_result
  #   if(self.qc_loa_qpcr)
  #     return self.qc_loa_qpcr
  #   else
  #     return @qc_loa_qpcr
  #   end
  # end

  # def qc_loa_qpcr_result=(arg)
  #   if(! self.qc_loa_qpcr)
  #     @qc_loa_qpcr = arg
  #   end
  # end

  # # qc_homozygous_loa_sr_pcr
  # def qc_homozygous_loa_sr_pcr_result
  #   if(self.qc_homozygous_loa_sr_pcr)
  #     return self.qc_homozygous_loa_sr_pcr
  #   else
  #     return @qc_homozygous_loa_sr_pcr
  #   end
  # end

  # def qc_homozygous_loa_sr_pcr_result=(arg)
  #   if(! self.qc_homozygous_loa_sr_pcr)
  #     @qc_homozygous_loa_sr_pcr = arg
  #   end
  # end

  # # qc_lacz_sr_pcr
  # def qc_lacz_sr_pcr_result
  #   if(self.qc_lacz_sr_pcr)
  #     return self.qc_lacz_sr_pcr
  #   else
  #     return @qc_lacz_sr_pcr
  #   end
  # end

  # def qc_lacz_sr_pcr_result=(arg)
  #   if(! self.qc_lacz_sr_pcr)
  #     @qc_lacz_sr_pcr = arg
  #   end
  # end

  # # qc_mutant_specific_sr_pcr
  # def qc_mutant_specific_sr_pcr_result
  #   if(self.qc_mutant_specific_sr_pcr)
  #     return self.qc_mutant_specific_sr_pcr
  #   else
  #     return @qc_mutant_specific_sr_pcr
  #   end
  # end

  # def qc_mutant_specific_sr_pcr_result=(arg)
  #   if(! self.qc_mutant_specific_sr_pcr)
  #     @qc_mutant_specific_sr_pcr = arg
  #   end
  # end

  # # qc_loxp_confirmation
  # def qc_loxp_confirmation_result
  #   if(self.qc_loxp_confirmation)
  #     return self.qc_loxp_confirmation
  #   else
  #     return @qc_loxp_confirmation
  #   end
  # end

  # def qc_loxp_confirmation_result=(arg)
  #   if(! self.qc_loxp_confirmation)
  #     @qc_loxp_confirmation = arg
  #   end
  # end

  # # qc_three_prime_lr_pcr
  # def qc_three_prime_lr_pcr_result
  #   if(self.qc_three_prime_lr_pcr)
  #     return self.qc_three_prime_lr_pcr
  #   else
  #     return @qc_three_prime_lr_pcr
  #   end
  # end

  # def qc_three_prime_lr_pcr_result=(arg)
  #   if(! self.qc_three_prime_lr_pcr)
  #     @qc_three_prime_lr_pcr = arg
  #   end
  # end

  # # qc_critical_region_qpcr
  # def qc_critical_region_qpcr_result
  #   if(self.qc_critical_region_qpcr)
  #     return self.qc_critical_region_qpcr
  #   else
  #     return @qc_critical_region_qpcr
  #   end
  # end

  # def qc_critical_region_qpcr_result=(arg)
  #   if(! self.qc_critical_region_qpcr)
  #     @qc_critical_region_qpcr = arg
  #   end
  # end

  # # qc_loxp_srpcr
  # def qc_loxp_srpcr_result
  #   if(self.qc_loxp_srpcr)
  #     return self.qc_loxp_srpcr
  #   else
  #     return @qc_loxp_srpcr
  #   end
  # end

  # def qc_loxp_srpcr_result=(arg)
  #   if(! self.qc_loxp_srpcr)
  #     @qc_loxp_srpcr = arg
  #   end
  # end

  # # qc_loxp_srpcr_and_sequencing
  # def qc_loxp_srpcr_and_sequencing_result
  #   if(self.qc_loxp_srpcr_and_sequencing)
  #     return self.qc_loxp_srpcr_and_sequencing
  #   else
  #     return @qc_loxp_srpcr_and_sequencing
  #   end
  # end

  # def qc_loxp_srpcr_and_sequencing_result=(arg)
  #   if(! self.qc_loxp_srpcr_and_sequencing)
  #     @qc_loxp_srpcr_and_sequencing = arg
  #   end
  # end

end

# == Schema Information
#
# Table name: colony_qcs
#
#  id                               :integer          not null, primary key
#  colony_id                        :integer          not null
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
#
# Indexes
#
#  index_colony_qcs_on_colony_id  (colony_id) UNIQUE
#

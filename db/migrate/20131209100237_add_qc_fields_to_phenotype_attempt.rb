class AddQcFieldsToPhenotypeAttempt < ActiveRecord::Migration

  #QC_FIELDS = [
  #  :qc_southern_blot,
  #  :qc_five_prime_lr_pcr,
  #  :qc_five_prime_cassette_integrity,
  #  :qc_tv_backbone_assay,
  #  :qc_neo_count_qpcr,
  #  :qc_lacz_count_qpcr,
  #  :qc_neo_sr_pcr,
  #  :qc_loa_qpcr,
  #  :qc_homozygous_loa_sr_pcr,
  #  :qc_lacz_sr_pcr,
  #  :qc_mutant_specific_sr_pcr,
  #  :qc_loxp_confirmation,
  #  :qc_three_prime_lr_pcr,
  #  :qc_critical_region_qpcr,
  #  :qc_loxp_srpcr,
  #  :qc_loxp_srpcr_and_sequencing
  #]

  QC_FIELDS = [
    :qc_southern_blot_id,
    :qc_five_prime_lr_pcr_id,
    :qc_five_prime_cassette_integrity_id,
    :qc_tv_backbone_assay_id,
    :qc_neo_count_qpcr_id,
    :qc_neo_sr_pcr_id,
    :qc_loa_qpcr_id,
    :qc_homozygous_loa_sr_pcr_id,
    :qc_lacz_sr_pcr_id,
    :qc_mutant_specific_sr_pcr_id,
    :qc_loxp_confirmation_id,
    :qc_three_prime_lr_pcr_id,
    :qc_lacz_count_qpcr_id,
    :qc_critical_region_qpcr_id,
    :qc_loxp_srpcr_id,
    :qc_loxp_srpcr_and_sequencing_id
  ]

  def up
    QC_FIELDS.each do |qc_field|
      add_column :phenotype_attempts, qc_field, :integer
    end

    QC_FIELDS.each do |qc_field|
      add_foreign_key :phenotype_attempts, :qc_results, :column => qc_field
    end
  end

  def down
    #QC_FIELDS.each do |qc_field|
    #  remove_foreign_key :phenotype_attempts, :qc_result_phenotypes
    #end

    QC_FIELDS.each do |qc_field|
      remove_column :phenotype_attempts, qc_field
    end
  end
end

# encoding: utf-8

class CreateMiAttempts < ActiveRecord::Migration

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
    :qc_three_prime_lr_pcr_id
  ]
  def self.up
    create_table :mi_attempts do |table|

      # Important fields / Admin Details
      table.references :clone, :null => false
      table.date :mi_date
      table.references :mi_attempt_status, :null => false
      table.text :colony_name
      table.integer :production_centre_id, :null => false
      table.integer :distribution_centre_id
      table.integer :updated_by_id

      # Transfer details
      table.references :blast_strain
      table.integer :total_blasts_injected
      table.integer :total_transferred
      table.integer :number_surrogates_receiving

      # Litter details
      table.integer :total_pups_born
      table.integer :total_female_chimeras
      table.integer :total_male_chimeras
      table.integer :total_chimeras
      table.integer :number_of_males_with_0_to_39_percent_chimerism
      table.integer :number_of_males_with_40_to_79_percent_chimerism
      table.integer :number_of_males_with_80_to_99_percent_chimerism
      table.integer :number_of_males_with_100_percent_chimerism

      # Chimera Mating Details
      table.boolean :is_suitable_for_emma, :null => false, :default => false
      table.boolean :is_emma_sticky      , :null => false, :default => false
      table.references :colony_background_strain
      table.references :test_cross_strain
      table.date :date_chimeras_mated
      table.integer :number_of_chimera_matings_attempted
      table.integer :number_of_chimera_matings_successful
      table.integer :number_of_chimeras_with_glt_from_cct
      table.integer :number_of_chimeras_with_glt_from_genotyping
      table.integer :number_of_chimeras_with_0_to_9_percent_glt
      table.integer :number_of_chimeras_with_10_to_49_percent_glt
      table.integer :number_of_chimeras_with_50_to_99_percent_glt
      table.integer :number_of_chimeras_with_100_percent_glt
      table.integer :total_f1_mice_from_matings
      table.integer :number_of_cct_offspring
      table.integer :number_of_het_offspring
      table.integer :number_of_live_glt_offspring
      table.text :mouse_allele_type

      # QC Details
      QC_FIELDS.each do |qc_field|
        table.integer qc_field
      end
      table.boolean :should_export_to_mart,       :null => false, :default => true
      table.boolean :is_active,                   :null => false, :default => true
      table.boolean :is_released_from_genotyping, :null => false, :default => false

      # Misc
      table.text :comments

      table.timestamps
    end

    add_foreign_key :mi_attempts, :clones
    add_foreign_key :mi_attempts, :mi_attempt_statuses
    add_foreign_key :mi_attempts, :centres, :column => :production_centre_id
    add_foreign_key :mi_attempts, :centres, :column => :distribution_centre_id
    add_foreign_key :mi_attempts, :users, :column => :updated_by_id
    add_foreign_key :mi_attempts, :strain_blast_strains, :column => :blast_strain_id
    add_foreign_key :mi_attempts, :strain_colony_background_strains, :column => :colony_background_strain_id
    add_foreign_key :mi_attempts, :strain_test_cross_strains, :column => :test_cross_strain_id
    QC_FIELDS.each { |qc_field| add_foreign_key :mi_attempts, :qc_statuses, :column => qc_field}
  end

  def self.down
    drop_table :mi_attempts
  end
end

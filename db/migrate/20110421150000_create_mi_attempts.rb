class CreateMiAttempts < ActiveRecord::Migration
  def self.up
    create_table :mi_attempts do |table|

      # Important fields / Admin Details
      table.references :clone, :null => false
      table.date :mi_date
      table.references :mi_attempt_status, :null => false
      table.text :colony_name
      table.references :centre
      table.integer :distribution_centre_id

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

      # QC Details
      # TODO: All are foreign keys to qc_statuses table
      table.integer :qc_southern_blot_id
      table.integer :qc_five_prime_lrpcr_id
      table.integer :qc_five_prime_cassette_integrity_id
      table.integer :qc_tv_backbone_assay_id
      table.integer :qc_neo_count_qpcr_id
      table.integer :qc_neo_sr_pcr_id
      table.integer :qc_loa_qpcr_id
      table.integer :qc_homozygous_loa_sr_pcr_id
      table.integer :qc_lacz_sr_pcr_id
      table.integer :qc_mutant_specific_sr_pcr_id
      table.integer :qc_loxp_confirmation_id
      table.integer :qc_three_prime_lr_pcr_id

      table.timestamps
    end

    add_foreign_key :mi_attempts, :clones
    add_foreign_key :mi_attempts, :mi_attempt_statuses
    add_foreign_key :mi_attempts, :centres
    add_foreign_key :mi_attempts, :centres, :column => :distribution_centre_id
    add_foreign_key :mi_attempts, :blast_strains
    add_foreign_key :mi_attempts, :colony_background_strains
    add_foreign_key :mi_attempts, :test_cross_strains
  end

  def self.down
    drop_table :mi_attempts
  end
end

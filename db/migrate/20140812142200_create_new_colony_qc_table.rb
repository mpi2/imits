class CreateNewColonyQcTable < ActiveRecord::Migration
  def self.up
    create_table :colony_qcs do |t|
      t.integer :colony_id, :null => false
      t.string :qc_southern_blot, :null => false
      t.string :qc_five_prime_lr_pcr, :null => false
      t.string :qc_five_prime_cassette_integrity, :null => false
      t.string :qc_tv_backbone_assay, :null => false
      t.string :qc_neo_count_qpcr, :null => false
      t.string :qc_lacz_count_qpcr, :null => false
      t.string :qc_neo_sr_pcr, :null => false
      t.string :qc_loa_qpcr, :null => false
      t.string :qc_homozygous_loa_sr_pcr, :null => false
      t.string :qc_lacz_sr_pcr, :null => false
      t.string :qc_mutant_specific_sr_pcr, :null => false
      t.string :qc_loxp_confirmation, :null => false
      t.string :qc_three_prime_lr_pcr, :null => false
      t.string :qc_critical_region_qpcr, :null => false
      t.string :qc_loxp_srpcr, :null => false
      t.string :qc_loxp_srpcr_and_sequencing, :null => false
    end

    add_foreign_key :colony_qcs, :colonies, :column => :colony_id, :name => 'colony_qcs_colonies_fk'
    add_index :colony_qcs, [:colony_id], :unique => true, :colony_id => :colony_id_index
  end

  def self.down
    drop_table :colony_qcs
  end

end
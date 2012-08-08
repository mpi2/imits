class AddOneStatusStampPerStatusContraint < ActiveRecord::Migration
  def self.up
    add_index :mi_plan_status_stamps, [:status_id, :mi_plan_id], :unique => true, :name => 'index_one_status_stamp_per_status_and_mi_plan'
    add_index :mi_attempt_status_stamps, [:status_id, :mi_attempt_id], :unique => true, :name => 'index_one_status_stamp_per_status_and_mi_attempt'
    add_index :phenotype_attempt_status_stamps, [:status_id, :phenotype_attempt_id], :unique => true, :name => 'index_one_status_stamp_per_status_and_phenotype_attempt'
  end

  def self.down
    remove_index :phenotype_attempt_status_stamps, :name => 'index_one_status_stamp_per_status_and_phenotype_attempt'
    remove_index :mi_attempt_status_stamps, :name => 'index_one_status_stamp_per_status_and_mi_attempt'
    remove_index :mi_plan_status_stamps, :name => 'index_one_status_stamp_per_status_and_mi_plan'
  end
end

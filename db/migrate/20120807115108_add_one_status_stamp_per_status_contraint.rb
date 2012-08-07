class AddOneStatusStampPerStatusContraint < ActiveRecord::Migration
  def self.up
    add_index :mi_plan_status_stamps, [:status_id, :mi_plan_id], :unique => true
    add_index :mi_attempt_status_stamps, [:status_id, :mi_attempt_id], :unique => true
    add_index :phenotype_attempt_status_stamps, [:status_id, :phenotype_attempt_id], :unique => true
  end

  def self.down
    remove_index :phenotype_attempt_status_stamps, [:status_id, :phenotype_attempt_id]
    remove_index :mi_attempt_status_stamps, [:status_id, :mi_attempt_id]
    remove_index :mi_plan_status_stamps, [:status_id, :mi_plan_id]
  end
end

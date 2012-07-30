class RenameAllMiAttemptStatusIdFieldsToStatusId < ActiveRecord::Migration
  def self.up
    rename_column :mi_attempts, :mi_attempt_status_id, :status_id
    rename_column :mi_attempt_status_stamps, :mi_attempt_status_id, :status_id
  end

  def self.down
    rename_column :mi_attempt_status_stamps, :status_id, :mi_attempt_status_id
    rename_column :mi_attempts, :status_id, :mi_attempt_status_id
  end
end

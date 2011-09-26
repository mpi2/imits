class CreateMiAttemptStatusStamps < ActiveRecord::Migration
  def self.up
    create_table :mi_attempt_status_stamps do |table|
      table.integer :mi_attempt_id, :null => false
      table.integer :mi_attempt_status_id, :null => false

      table.timestamps
    end
    add_foreign_key :mi_attempt_status_stamps, :mi_attempts
    add_foreign_key :mi_attempt_status_stamps, :mi_attempt_statuses
  end

  def self.down
    drop_table :mi_attempt_status_stamps
  end
end

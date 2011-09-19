class CreateMiAttemptStatusStamps < ActiveRecord::Migration
  class MiAttempt < ActiveRecord::Base; end
  class MiAttempt::StatusStamp < ActiveRecord::Base; end

  def self.up
    create_table :mi_attempt_status_stamps do |table|
      table.integer :mi_attempt_id, :null => false
      table.integer :mi_attempt_status_id, :null => false

      table.timestamps
    end

    MiAttempt.all.each do |mi_attempt|
      MiAttempt::StatusStamp.create!(:mi_attempt_id => mi_attempt.id,
        :mi_attempt_status_id => mi_attempt.mi_attempt_status_id)
    end

    remove_column :mi_attempts, :mi_attempt_status_id
  end

  def self.down
    add_column :mi_attempts, :mi_attempt_status_id, :integer
    MiAttempt::StatusStamp.all.each do |status_stamp|
      mi_attempt = MiAttempt.find_by_id!(status_stamp.mi_attempt_id)
      status = MiAttemptStatus.find_by_id!(status_stamp.mi_attempt_status_id)
      mi_attempt.mi_attempt_status_id = status.id
      mi_attempt.save!
    end
    change_column :mi_attempts, :mi_attempt_status_id, :integer, :null => false
    add_foreign_key :mi_attempts, :mi_attempt_statuses

    drop_table :mi_attempt_status_stamps
  end
end

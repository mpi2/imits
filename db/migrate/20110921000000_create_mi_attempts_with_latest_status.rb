class CreateMiAttemptsWithLatestStatus < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW mi_attempts_with_latest_status AS
      SELECT mi_attempts.*,
             (
               SELECT mi_attempt_status_stamps.mi_attempt_status_id
               FROM mi_attempt_status_stamps
               WHERE mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id
               ORDER BY mi_attempt_status_stamps.created_at DESC
               LIMIT 1
             ) latest_mi_attempt_status_id
      FROM mi_attempts;
    SQL
  end

  def self.down
    execute 'DROP VIEW mi_attempts_with_latest_status'
  end
end

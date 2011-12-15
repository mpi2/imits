class CreatePhenotypeAttemptStatusStamps < ActiveRecord::Migration
  def self.up
    create_table :phenotype_attempt_status_stamps do |table|
      table.integer :phenotype_attempt_id, :null => false
      table.integer :status_id, :null => false

      table.timestamps
    end
    add_foreign_key :phenotype_attempt_status_stamps, :phenotype_attempt_statuses, :column => :status_id
    add_foreign_key :phenotype_attempt_status_stamps, :phenotype_attempts
  end

  def self.down
    drop_table :phenotype_attempt_status_stamps
  end
end

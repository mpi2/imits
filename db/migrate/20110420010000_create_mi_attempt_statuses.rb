class CreateMiAttemptStatuses < ActiveRecord::Migration
  def self.up
    create_table :mi_attempt_statuses do |t|
      t.text :description, :null => false

      t.timestamps
    end
    add_index :mi_attempt_statuses, :description, :unique => true
  end

  def self.down
    drop_table :mi_attempt_statuses
  end
end

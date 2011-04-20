class CreateMiAttemptStatuses < ActiveRecord::Migration
  def self.up
    create_table :mi_attempt_statuses do |t|
      t.text :description, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :mi_attempt_statuses
  end
end

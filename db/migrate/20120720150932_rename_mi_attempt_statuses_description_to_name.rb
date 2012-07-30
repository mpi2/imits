class RenameMiAttemptStatusesDescriptionToName < ActiveRecord::Migration
  def self.up
    remove_index :mi_attempt_statuses, :description
    rename_column(:mi_attempt_statuses, :description, :name)
    add_index :mi_attempt_statuses, :name, :unique => true
  end

  def self.down
    remove_index :mi_attempt_statuses, :name
    rename_column(:mi_attempt_statuses, :name, :description)
    add_index :mi_attempt_statuses, :description, :unique => true
  end
end

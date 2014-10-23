class RenameColonyNameOnMiAttempt < ActiveRecord::Migration
  def self.up
    rename_column :mi_attempts, :colony_name, :external_ref
  end

  def self.down
    rename_column :mi_attempts, :external_ref, :colony_name
  end
end

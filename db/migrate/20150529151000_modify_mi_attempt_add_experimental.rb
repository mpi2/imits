class ModifyMiAttemptAddExperimental < ActiveRecord::Migration
  def self.up
    add_column :mi_attempts, :experimental, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :mi_attempts, :experimental
  end

end
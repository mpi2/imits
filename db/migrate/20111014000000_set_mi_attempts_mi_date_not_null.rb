class SetMiAttemptsMiDateNotNull < ActiveRecord::Migration
  def self.up
    change_column :mi_attempts, :mi_date, :date, :null => false
  end

  def self.down
    change_column :mi_attempts, :mi_date, :date, :null => true
  end
end

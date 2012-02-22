class AddIsActiveToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :is_active, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :mi_plans, :is_active
  end
end


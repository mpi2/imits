class ChangePriorityColumnOnMiPlan < ActiveRecord::Migration
  def self.up
    change_column :mi_plans, :priority_id, :integer, :null => true
  end

  def self.down
    change_column :mi_plans, :priority_id, :integer,  :null => true
  end
end

class FixMiPlanSubProjectDefaults < ActiveRecord::Migration
  def self.up
    execute('update mi_plans set sub_project_id = 1')
    change_column :mi_plans, :sub_project_id, :integer, :null => false
  end

  def self.down
    change_column :mi_plans, :sub_project_id, :integer, :null => true
  end
end

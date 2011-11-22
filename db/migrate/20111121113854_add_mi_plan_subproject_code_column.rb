class AddMiPlanSubprojectCodeColumn < ActiveRecord::Migration
  def self.up
    
    #change_table :mi_plans do |t|
    #  t.references :mi_plan_sub_project
    #end
    
    add_column :mi_plans, :mi_plan_sub_project_id, :integer

#      table.references :mi_plan_status, :null => false

    add_foreign_key :mi_plans, :mi_plan_sub_projects
  end

  def self.down
    remove_column :mi_plans, :mi_plan_sub_project_id
  end
end

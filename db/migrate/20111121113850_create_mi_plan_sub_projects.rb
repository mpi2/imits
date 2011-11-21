class CreateMiPlanSubProjects < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_sub_projects do |table|
      table.string :name, :null => false
      table.timestamps
    end
  end

  def self.down
    drop_table :mi_plan_sub_projects   
  end
end

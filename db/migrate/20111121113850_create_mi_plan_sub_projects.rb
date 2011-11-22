class CreateMiPlanSubProjects < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_sub_projects do |table|
      table.string :name, :null => false
      table.timestamps
    end

    add_column :mi_plans, :sub_project_id, :integer

    add_foreign_key :mi_plans, :mi_plan_sub_projects, :column => 'sub_project_id'
    
    #:column => 'article_id'
#    add_foreign_key :mi_plans, :sub_projects

  end

  def self.down
    remove_column :mi_plans, :sub_project_id
    
    drop_table :mi_plan_sub_projects   
  end
end

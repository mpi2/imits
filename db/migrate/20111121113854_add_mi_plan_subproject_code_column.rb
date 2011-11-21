class AddMiPlanSubprojectCodeColumn < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :mi_plan_sub_project_id, :integer

    #add_foreign_key :mi_plans, :mi_plan_sub_projects
    add_foreign_key :mi_plans, :mi_plan_sub_projects#, :source_column => :sub_project_id
    #  add_foreign_key :comments, :posts, :source_column => :my_parent_post_id
  end

  def self.down
    remove_column :mi_plans, :mi_plan_sub_project_id
  end
end

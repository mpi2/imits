class ReindexMiPlanLogicalKey < ActiveRecord::Migration
  def self.up
    remove_index :mi_plans, :name => :mi_plan_logical_key
    add_index :mi_plans, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id], :unique => true, :name => :mi_plan_logical_key
  end

  def self.down
    remove_index :mi_plans, :name => :mi_plan_logical_key
  end
end

class CreateMiPlans < ActiveRecord::Migration
  def self.up
    create_table :mi_plan_statuses do |t|
      t.string :name, :limit => 50, :null => false, :unique => true

      t.timestamps
    end

    create_table :mi_plan_priorities do |t|
      t.string :name, :limit => 10, :null => false, :unique => true
      t.string :description, :limit => 100

      t.timestamps
    end

    create_table :mi_plans do |t|
      t.references :gene, :null => false
      t.references :consortium, :null => false
      t.references :mi_plan_status, :null => false
      t.references :mi_plan_priority, :null => false
      t.integer :production_centre_id

      t.timestamps
    end

    add_foreign_key :mi_plans, :genes
    add_foreign_key :mi_plans, :consortia
    add_foreign_key :mi_plans, :mi_plan_statuses
    add_foreign_key :mi_plans, :mi_plan_priorities
    add_foreign_key :mi_plans, :centres, :column => :production_centre_id

    add_index :mi_plans, [:gene_id, :consortium_id], :unique => true
  end

  def self.down
    drop_table :mi_plans
    drop_table :mi_plan_priorities
    drop_table :mi_plan_statuses
  end
end

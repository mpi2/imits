class AddGrantGoals < ActiveRecord::Migration

  def self.up
    create_table :grants do |t|
      t.string :name, :null => false
      t.string :funding, :null => false
      t.integer :consortium_id, :null => false
      t.integer :production_centre_id, :null => false
      t.date :commence, :null => false
      t.date :end, :null => false
      t.string :injection_stategy, :null => false
    end

    create_table :grant_goals do |t|
      t.integer :grant_id, :null => false
      t.integer :year, :null => false
      t.integer :month, :null => false
      t.integer :crispr_mi_goal
      t.integer :crispr_gc_goal
      t.integer :es_cell_mi_goal
      t.integer :es_cell_gc_goal
      t.integer :total_mi_goal
      t.integer :total_gc_goal
      t.integer :excision_goal
      t.integer :phenotype_goal
      t.boolean :crispr_mi_goal_automatically_set, :default => false, :null => false
      t.boolean :crispr_gc_goal_automatically_set, :default => false, :null => false
      t.boolean :es_cell_mi_goal_automatically_set, :default => false, :null => false
      t.boolean :es_cell_gc_goal_automatically_set, :default => false, :null => false
      t.boolean :excision_goal_automatically_set, :default => false, :null => false
      t.boolean :phenotyping_goal_automatically_set, :default => false, :null => false
    end
  end

  def self.down
    drop_table :grant_goals
    drop_table :grants
  end
end

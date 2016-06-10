class AddGrantGoals < ActiveRecord::Migration

  def self.up
    create_table :grants do |t|
      t.string :name, :null => false
      t.string :funding, :null => false
      t.integer :consortium_id, :null => false
      t.integer :production_centre_id, :null => false
      t.date :commence_date, :null => false
      t.date :end_date, :null => false
    end

    create_table :grant_goals do |t|
      t.integer :grant_id, :null => false
      t.integer :year, :null => false
      t.integer :month, :null => false
      t.integer :cum_crispr_mi_goal
      t.integer :cum_crispr_gc_goal
      t.integer :cum_es_cell_mi_goal
      t.integer :cum_es_cell_gc_goal
      t.integer :cum_total_mi_goal
      t.integer :cum_total_gc_goal
      t.integer :cum_excision_goal
      t.integer :cum_phenotype_goal
      t.boolean :crispr_mi_goal_automatically_set, :default => false, :null => false
      t.boolean :crispr_gc_goal_automatically_set, :default => false, :null => false
      t.boolean :es_cell_mi_goal_automatically_set, :default => false, :null => false
      t.boolean :es_cell_gc_goal_automatically_set, :default => false, :null => false
      t.boolean :excision_goal_automatically_set, :default => false, :null => false
      t.boolean :phenotype_goal_automatically_set, :default => false, :null => false
    end
  end

  def self.down
    drop_table :grant_goals
    drop_table :grants
  end
end

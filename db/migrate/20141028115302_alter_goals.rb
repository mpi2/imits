class AlterGoals < ActiveRecord::Migration

  def self.up
    add_column :production_goals, :crispr_mi_goal, :integer, :default => 0
    add_column :production_goals, :crispr_gc_goal, :integer, :default => 0
    add_column :production_goals, :total_mi_goal, :integer, :default => 0
    add_column :production_goals, :total_gc_goal, :integer, :default => 0

    add_column :tracking_goals, :crispr_goal, :integer, :default => 0
    add_column :tracking_goals, :total_goal, :integer, :default => 0
  end

  def self.down
    remove_column :production_goals, :crispr_mi_goal
    remove_column :production_goals, :crispr_gc_goal
    remove_column :production_goals, :total_mi_goal
    remove_column :production_goals, :total_gc_goal

    remove_column :tracking_goals, :crispr_goal
    remove_column :tracking_goals, :total_goal
  end
end

class AlterGoalsForCrisprData < ActiveRecord::Migration

  def self.up
    change_column_default :production_goals, :crispr_mi_goal, nil
    change_column_default :production_goals, :crispr_gc_goal, nil
    change_column_default :production_goals, :total_mi_goal, nil
    change_column_default :production_goals, :total_gc_goal, nil
  end

  def self.down
    change_column :production_goals, :crispr_mi_goal, :integer, :default => 0
    change_column :production_goals, :crispr_gc_goal, :integer, :default => 0
    change_column :production_goals, :total_mi_goal, :integer, :default => 0
    change_column :production_goals, :total_gc_goal, :integer, :default => 0
  end
end

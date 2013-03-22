class AddProjectCompletionNoteAndRecoveryToMiPlan < ActiveRecord::Migration
  def up
    add_column :mi_plans, :completion_note, :string, :limit => 100
    add_column :mi_plans, :recovery, :boolean
  end

  def down
    remove_column :mi_plans, :completion_note
    remove_column :mi_plans, :recovery
  end
end

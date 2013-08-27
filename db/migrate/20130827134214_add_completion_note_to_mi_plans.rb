class AddCompletionNoteToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :completion_comment, :text
  end

  def self.down
    remove_column :mi_plans, :completion_comment
  end
end

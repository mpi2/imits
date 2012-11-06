class AddPipelineNameIndex < ActiveRecord::Migration
  def self.up
    add_index :targ_rep_pipelines, :name, :unique => true
  end

  def self.down
    remove_index :targ_rep_pipelines, :name
  end
end

class AddLegacyIdToPipeline < ActiveRecord::Migration
  def self.up
    add_column :targ_rep_pipelines, :legacy_id, :integer
  end

  def self.down
    remove_column :targ_rep_pipelines, :legacy_id
  end
end

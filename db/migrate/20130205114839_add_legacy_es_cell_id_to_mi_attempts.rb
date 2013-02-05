class AddLegacyEsCellIdToMiAttempts < ActiveRecord::Migration
  def self.up
    add_column :mi_attempts, :legacy_es_cell_id, :integer
  end

  def self.down
    remove_column :mi_attempts, :legacy_es_cell_id
  end
end

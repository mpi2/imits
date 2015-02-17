class GeneAddMarkerNameAndCmPosition < ActiveRecord::Migration

  def self.up
    add_column :genes, :marker_name, :string
    add_column :genes, :cm_position, :string
  end

  def self.down
    remove_column :genes, :marker_name, :string
    remove_column :genes, :cm_position, :string
  end
end

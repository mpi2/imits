class AddMarkerTypeToGene < ActiveRecord::Migration
  def change
    add_column :genes, :marker_type, :string
  end
end

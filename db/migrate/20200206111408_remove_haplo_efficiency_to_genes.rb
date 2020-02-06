class RemoveHaploEfficiencyToGenes < ActiveRecord::Migration
  def up
  	remove_column :genes, :haplo_efficiency
  end

  def down
  	add_column :genes, :haplo_efficiency, :boolean, default: false 
  end
end

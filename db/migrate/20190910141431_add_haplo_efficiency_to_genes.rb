class AddHaploEfficiencyToGenes < ActiveRecord::Migration
  def self.up
    add_column :genes, :haplo_efficiency, :boolean, default: false 
  end

  def self.down
    remove_column :genes, :haplo_efficiency
  end
end

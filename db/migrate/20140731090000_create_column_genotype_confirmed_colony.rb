class CreateColumnGenotypeConfirmedColony < ActiveRecord::Migration
  def self.up
    add_column :colonies, :genotype_confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :colonies, :genotype_confirmed
  end
end

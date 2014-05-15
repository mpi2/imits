class AlterPhenotypingTables < ActiveRecord::Migration

  def self.up

    add_column :phenotype_attempts, :ready_for_website, :date
    add_column :phenotyping_productions, :ready_for_website, :date

    change_column :phenotyping_productions, :colony_name, :string, :null => true
  end

  def self.down
    remove_column :phenotype_attempts, :ready_for_website
    remove_column :phenotyping_productions, :ready_for_website

    change_column :phenotyping_productions, :colony_name, :string, :null => false

  end
end

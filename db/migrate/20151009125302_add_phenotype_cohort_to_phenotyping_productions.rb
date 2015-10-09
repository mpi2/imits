class AddPhenotypeCohortToPhenotypingProductions < ActiveRecord::Migration

  def self.up
    add_column :phenotyping_productions, :cohort_production_centre_id, :integer
  end

  def self.down
    remove_column :phenotyping_productions, :cohort_production_centre_id
  end


end

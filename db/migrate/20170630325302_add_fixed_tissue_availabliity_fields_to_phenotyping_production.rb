class AddFixedTissueAvailabliityFieldsToPhenotypingProduction < ActiveRecord::Migration

  def self.up
    create_table :phenotyping_production_tissue_distribution_centres do |table|
      table.date :start_date
      table.date :end_date
      table.integer :phenotyping_production_id, :null => false
      table.string :deposited_material, :null => false
      table.integer :centre_id, :null => false

      table.timestamps
    end

    add_foreign_key :phenotyping_production_tissue_distribution_centres, :phenotyping_productions, name: :fk_tdc_phenotyinging_production
    add_foreign_key :phenotyping_production_tissue_distribution_centres, :centres, name: :fk_tdc_centre
  end

  def self.down
    drop_table :phenotyping_production_tissue_distribution_centres
  end

end

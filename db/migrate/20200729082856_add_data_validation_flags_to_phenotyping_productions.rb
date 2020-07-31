class AddDataValidationFlagsToPhenotypingProductions < ActiveRecord::Migration
  def change
  	add_column :phenotyping_productions, :all_data_sent, :boolean, default: false
  	add_column :phenotyping_productions, :all_data_processed, :boolean, default: false
  	add_column :phenotyping_productions, :qc_complete, :boolean, default: false
  end
end

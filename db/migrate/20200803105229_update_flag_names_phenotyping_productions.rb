class UpdateFlagNamesPhenotypingProductions < ActiveRecord::Migration
  def change
  	rename_column :phenotyping_productions, :qc_complete, :phenotyping_finished
  end
end

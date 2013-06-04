class AddProductionCentreAutoUpdate < ActiveRecord::Migration
  def up
    add_column :targ_rep_es_cells, :production_centre_auto_update, :boolean, :default => true
  end

  def down
    remove_column :targ_rep_es_cells, :production_centre_auto_update
  end
end

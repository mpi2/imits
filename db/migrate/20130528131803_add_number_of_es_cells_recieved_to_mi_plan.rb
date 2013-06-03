class AddNumberOfEsCellsRecievedToMiPlan < ActiveRecord::Migration
  def change
    add_column :mi_plans, :number_of_es_cells_received, :integer
    add_column :mi_plans, :es_cells_received_on, :date
    add_column :mi_plans, :es_cells_received_from_id, :integer
  end
end

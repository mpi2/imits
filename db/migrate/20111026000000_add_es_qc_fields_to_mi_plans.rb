class AddEsQcFieldsToMiPlans < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :number_of_es_cells_starting_qc, :integer
    add_column :mi_plans, :number_of_es_cells_passing_qc, :integer
  end

  def self.down
    remove_column :mi_plans, :number_of_es_cells_passing_qc
    remove_column :mi_plans, :number_of_es_cells_starting_qc
  end
end

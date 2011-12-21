class AddIkmcProjectIdAndMutationTypeToEsCells < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :ikmc_project_id, :string, :limit => 100
    add_column :es_cells, :mutation_type, :string, :limit => 100
  end

  def self.down
    remove_column :es_cells, :ikmc_project_id
    remove_column :es_cells, :mutation_type
  end
end

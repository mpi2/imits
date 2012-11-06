class AddEsCellDistributionCentreIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :es_cell_distribution_centre_id, :integer

    add_foreign_key :users, :targ_rep_es_cell_distribution_centres, :column => 'es_cell_distribution_centre_id'
  end

  def self.down
    remove_column :users, :es_cell_distribution_centre_id

    remove_foreign_key :users, :targ_rep_es_cell_distribution_centres
  end
end

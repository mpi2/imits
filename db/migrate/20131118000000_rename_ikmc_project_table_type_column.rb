class RenameIkmcProjectTableTypeColumn < ActiveRecord::Migration
  def self.up
    rename_column :targ_rep_ikmc_project_statuses, :type, :product_type
  end

  def self.down
    rename_column :targ_rep_ikmc_project_statuses, :product_type, :type
  end
end

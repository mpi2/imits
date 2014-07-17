class AddTaqmanColsToAlleles < ActiveRecord::Migration
  def change
  	add_column :targ_rep_alleles, :taqman_critical_del_assay_id, :string, :null => true
  	add_column :targ_rep_alleles, :taqman_upstream_del_assay_id, :string, :null => true
  	add_column :targ_rep_alleles, :taqman_downstream_del_assay_id, :string, :null => true
  end
end
class AddGeneTrapToTargRepPipelines < ActiveRecord::Migration
  def change
    add_column :targ_rep_pipelines, :gene_trap, :boolean, :default => false
  end
end

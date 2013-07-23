class AddNeoQpcrToEsCellDistributionQc < ActiveRecord::Migration
  def up
    add_column :targ_rep_distribution_qcs, :neo_qpcr, :string
  end

  def down
    remove_column :targ_rep_distribution_qcs, :neo_qpcr
  end
end

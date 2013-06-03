class AddUserQcData < ActiveRecord::Migration
  def up
    add_column :targ_rep_es_cells, :user_qc_chr1, :string
    add_column :targ_rep_es_cells, :user_qc_chr11, :string
    add_column :targ_rep_es_cells, :user_qc_chr8, :string
    add_column :targ_rep_es_cells, :user_qc_chry, :string
    add_column :targ_rep_es_cells, :user_qc_lacz_qpcr, :string
  end

  def down
    remove_column :targ_rep_es_cells, :user_qc_chr1
    remove_column :targ_rep_es_cells, :user_qc_chr11
    remove_column :targ_rep_es_cells, :user_qc_chr8
    remove_column :targ_rep_es_cells, :user_qc_chry
    remove_column :targ_rep_es_cells, :user_qc_lacz_qpcr
  end
end

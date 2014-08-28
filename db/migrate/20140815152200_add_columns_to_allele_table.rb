class AddColumnsToAlleleTable < ActiveRecord::Migration
  def change
  	add_column :targ_rep_alleles, :wildtype_oligos_sequence, :string
  end
end
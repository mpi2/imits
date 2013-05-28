class AddIntronToTargRepAlleles < ActiveRecord::Migration
  def change
    add_column :targ_rep_alleles, :intron, :integer
  end
end

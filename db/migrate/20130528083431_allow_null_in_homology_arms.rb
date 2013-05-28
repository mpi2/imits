class AllowNullInHomologyArms < ActiveRecord::Migration
  def up
    change_column :targ_rep_alleles, :homology_arm_start, :integer, :null => true
    change_column :targ_rep_alleles, :homology_arm_end, :integer, :null => true
  end

  def down
    change_column :targ_rep_alleles, :homology_arm_start, :integer, :null => false
    change_column :targ_rep_alleles, :homology_arm_end, :integer, :null => false
  end
end

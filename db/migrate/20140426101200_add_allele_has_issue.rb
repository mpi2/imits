class AddAlleleHasIssue < ActiveRecord::Migration
  def change
    add_column :targ_rep_alleles, :has_issue, :boolean, :default => false, :null => false
  end
end
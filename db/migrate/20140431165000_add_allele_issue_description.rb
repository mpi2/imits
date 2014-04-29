class AddAlleleIssueDescription < ActiveRecord::Migration
  def change
    add_column :targ_rep_alleles, :issue_description, :text
  end
end
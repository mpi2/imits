class AddMutationAlleleCodes < ActiveRecord::Migration

  def self.up
    add_column :targ_rep_mutation_methods, :allele_prefix, :string, :limit => 5
    add_column :targ_rep_mutation_types, :allele_code, :string, :limit => 5
  end

  def self.down
    remove_column :targ_rep_mutation_methods, :allele_prefix
    remove_column :targ_rep_mutation_types, :allele_code
  end


end

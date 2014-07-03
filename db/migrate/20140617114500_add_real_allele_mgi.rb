class AddRealAlleleMgi < ActiveRecord::Migration
  def change
  	change_column :targ_rep_real_alleles, :allele_name, :string, :null => false, :limit => 40
    add_column :targ_rep_real_alleles, :mgi_accession_id, :string, :null => true

    remove_foreign_key :targ_rep_targeting_vectors, :name => 'targ_rep_targeting_vectors_targ_rep_real_allele_id_fk'
    remove_column :targ_rep_targeting_vectors, :real_allele_id

    add_column :targ_rep_targeting_vectors, :mgi_allele_name_prediction, :string, :null => true, :limit => 40
    add_column :targ_rep_targeting_vectors, :allele_type_prediction, :string, :null => true, :limit => 10
  end
end
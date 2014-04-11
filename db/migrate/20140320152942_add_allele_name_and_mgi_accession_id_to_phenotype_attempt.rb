class AddAlleleNameAndMgiAccessionIdToPhenotypeAttempt < ActiveRecord::Migration
  def change
    add_column :phenotype_attempts, :allele_name, :string
    add_column :phenotype_attempts, :jax_mgi_accession_id, :string
  end
end

class AddCrisprData < ActiveRecord::Migration
  def change
    add_column :mi_attempts, :founder_num_assays, :integer
    add_column :mi_attempts, :founder_num_positive_results, :integer
    add_column :mi_attempts, :assay_type, :text

    add_column :mutagenesis_factors, :nuclease, :text

    add_column :colonies, :report_to_public, :boolean, :default => false
    add_column :colonies, :unwanted_allele, :boolean, :default => false
    add_column :colonies, :unwanted_allele_description, :text
  end
end

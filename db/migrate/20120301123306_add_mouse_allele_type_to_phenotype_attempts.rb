class AddMouseAlleleTypeToPhenotypeAttempts < ActiveRecord::Migration
  def self.up
    add_column :phenotype_attempts, :mouse_allele_type, :string, :limit => 1
  end

  def self.down
    remove_column :phenotype_attempts, :mouse_allele_type
  end
end

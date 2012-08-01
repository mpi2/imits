class ChangePhenotypeAttemptMouseAlleleTypeLimit < ActiveRecord::Migration
  def self.up
    change_column :phenotype_attempts, :mouse_allele_type, :string, :limit => 2
  end

  def self.down
    change_column :phenotype_attempts, :mouse_allele_type, :string, :limit => 1
  end
end

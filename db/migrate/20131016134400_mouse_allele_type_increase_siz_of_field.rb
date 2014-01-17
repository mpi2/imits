class MouseAlleleTypeIncreaseSizOfField < ActiveRecord::Migration

  def self.up
    change_column(:mi_attempts, :mouse_allele_type, :string, {:limit => 3})
    change_column(:phenotype_attempts, :mouse_allele_type, :string, :limit => 3)
  end
end

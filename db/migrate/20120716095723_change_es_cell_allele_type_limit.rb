class ChangeEsCellAlleleTypeLimit < ActiveRecord::Migration
  def self.up
    change_column :es_cells, :allele_type, :string, :limit => 2
  end

  def self.down
    change_column :es_cells, :allele_type, :string, :limit => 1
  end
end

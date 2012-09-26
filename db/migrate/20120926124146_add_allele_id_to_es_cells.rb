class AddAlleleIdToEsCells < ActiveRecord::Migration
  def self.up
    add_column :es_cells, :allele_id, :integer, :null => false, :default => 0
    change_column :es_cells, :allele_id, :integer, :default => nil
  end

  def self.down
    remove_column :es_cells, :allele_id
  end
end

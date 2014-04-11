class AddRefsToGeneTable < ActiveRecord::Migration

  def self.up
    add_column :genes, :chromosome, :string, :limit => 2
    add_column :genes, :start_coordinates, :integer
    add_column :genes, :end_coordinates, :integer
    add_column :genes, :strand, :string
    add_column :genes, :vega_ids, :string
    add_column :genes, :ncbi_ids, :string
    add_column :genes, :ensembl_ids, :string
    add_column :genes, :ccds_ids, :string

  end

  def self.down
    remove_column :genes, :chromosome
    remove_column :genes, :start_coordinates
    remove_column :genes, :end_coordinates
    remove_column :genes, :strand
    remove_column :genes, :vega_ids
    remove_column :genes, :ncbi_ids
    remove_column :genes, :ensembl_ids
    remove_column :genes, :ccds_ids
  end
end

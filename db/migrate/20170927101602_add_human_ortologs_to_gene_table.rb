class AddHumanOrtologsToGeneTable < ActiveRecord::Migration

  def self.up
    add_column :genes, :human_marker_symbol, :string
    add_column :genes, :human_entrez_gene_id, :string
    add_column :genes, :human_homolo_gene_id, :string
  end

  def self.down
    remove_column :genes, :human_marker_symbol
    remove_column :genes, :human_entrez_gene_id
    remove_column :genes, :human_homolo_gene_id
  end

end

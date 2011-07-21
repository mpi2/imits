class CreateGenes < ActiveRecord::Migration
  class BasicEsCell < ActiveRecord::Base
    set_table_name :es_cells
  end

  class BasicGene < ActiveRecord::Base
    set_table_name :genes
    has_many :es_cells, :class_name => 'BasicEsCell', :foreign_key => 'gene_id'
  end

  def self.up
    create_table :genes do |t|
      t.string :marker_symbol, :null => false, :limit => 75
      t.string :mgi_accession_id, :limit => 40
      t.timestamps
    end
    add_index :genes, :marker_symbol, :unique => true

    add_column :es_cells, :gene_id, :integer
    add_foreign_key :es_cells, :genes

    BasicEsCell.all.each do |es_cell|
      gene = BasicGene.find_or_create_by_marker_symbol(:marker_symbol => es_cell.marker_symbol, :mgi_accession_id => es_cell.mgi_accession_id)
      es_cell.gene_id = gene.id
      es_cell.save!
    end

    execute('alter table es_cells alter column gene_id set not null')

    remove_column :es_cells, :mgi_accession_id
    remove_column :es_cells, :marker_symbol
  end

  def self.down
    add_column :es_cells, :marker_symbol, :string, :limit => 75
    add_column :es_cells, :mgi_accession_id, :string, :limit => 40

    BasicGene.all.each do |gene|
      gene.es_cells.each do |es_cell|
        es_cell.mgi_accession_id = gene.mgi_accession_id
        es_cell.marker_symbol = gene.marker_symbol
        es_cell.save!
      end
    end

    execute('alter table es_cells alter column marker_symbol set not null')

    remove_column :es_cells, :gene_id
    drop_table :genes
  end
end

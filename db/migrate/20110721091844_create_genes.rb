class CreateGenes < ActiveRecord::Migration
  def self.up
    create_table :genes do |t|
      t.string :marker_symbol, :null => false, :limit => 75
      t.string :mgi_accession_id, :limit => 40
      t.timestamps
    end
    add_index :genes, :marker_symbol, :unique => true
    
    add_column :es_cells, :gene_id, :integer
    add_foreign_key :es_cells, :genes
    
    EsCell.all.each do |cell|
      gene = Gene.new( :marker_symbol => cell.marker_symbol, :mgi_accession_id => cell.mgi_accession_id ).save
      cell.gene_id = gene.id
      cell.save
    end

    execute('alter table es_cells alter column gene_id set not null')

    remove_column :es_cells, :mgi_accession_id
    remove_column :es_cells, :marker_symbol
  end

  def self.down
    add_column :es_cells, :marker_symbol, :string, :limit => 75
    add_column :es_cells, :mgi_accession_id, :string, :limit => 40
    
    Gene.all.each do |gene|
      gene.es_cells.each do |cell|
        cell.mgi_accession_id = gene.mgi_accession_id
        cell.marker_symbol = gene.marker_symbol
        cell.save
      end
    end
    
    execute('alter table es_cells alter column marker_symbol set not null')
    
    remove_foreign_key :es_cells, :genes
    remove_column :es_cells, :gene_id
    drop_table :genes
  end
end


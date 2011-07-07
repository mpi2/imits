class CreateEsCells< ActiveRecord::Migration
  def self.up
    create_table :es_cells do |t|
      t.text :name, :null => false
      t.text :marker_symbol, :null => false
      t.text :allele_symbol_superscript_template
      t.text :allele_type
      t.references :pipeline, :null => false
      t.text :mgi_accession_id

      t.timestamps
    end

    add_index :es_cells, :name, :unique => true
    add_foreign_key :es_cells, :pipelines
  end

  def self.down
    drop_table :es_cells
  end
end

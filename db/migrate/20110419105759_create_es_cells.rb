class CreateEsCells< ActiveRecord::Migration
  def self.up
    create_table :es_cells do |t|
      t.string :name, :null => false, :limit => 100
      t.string :marker_symbol, :null => false, :limit => 75
      t.string :allele_symbol_superscript_template, :limit => 75
      t.string :allele_type, :limit => 1
      t.references :pipeline, :null => false
      t.string :mgi_accession_id, :limit => 40

      t.timestamps
    end

    add_index :es_cells, :name, :unique => true
    add_foreign_key :es_cells, :pipelines
  end

  def self.down
    drop_table :es_cells
  end
end

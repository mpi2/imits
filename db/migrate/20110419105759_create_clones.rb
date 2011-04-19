class CreateClones < ActiveRecord::Migration
  def self.up
    create_table :clones do |t|
      t.text :clone_name, :null => false
      t.text :marker_symbol, :null => false
      t.text :allele_name_superscript, :null => false
      t.references :pipeline, :null => false

      t.timestamps
    end

    add_index :clones, :clone_name, :unique => true
    add_foreign_key :clones, :pipelines
  end

  def self.down
    drop_table :clones
  end
end

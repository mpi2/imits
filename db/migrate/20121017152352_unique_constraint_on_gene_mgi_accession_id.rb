class UniqueConstraintOnGeneMgiAccessionId < ActiveRecord::Migration
  def self.up
    add_index :genes, :mgi_accession_id, :unique => true
  end

  def self.down
    remove_index :genes, :mgi_accession_id
  end
end

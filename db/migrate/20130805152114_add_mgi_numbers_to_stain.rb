class AddMgiNumbersToStain < ActiveRecord::Migration
  def self.up
    add_column :strains, :mgi_strain_accession_id, :string, :limit => 100
    add_column :strains, :mgi_strain_name, :string, :limit => 100
  end

  def self.down
    remove_column :strains, :mgi_strain_accession_id
    remove_column :strains, :mgi_strain_name
  end
end

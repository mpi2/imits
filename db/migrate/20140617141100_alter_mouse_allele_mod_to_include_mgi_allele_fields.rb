class AlterMouseAlleleModToIncludeMgiAlleleFields < ActiveRecord::Migration
  def self.up
    # add columns to mouse_allele_mods
    add_column :mouse_allele_mods, :allele_name, :string
    add_column :mouse_allele_mods, :allele_mgi_accession_id, :string
  end

  def self.down
    # remove columns to mouse_allele_mods
    remove_column :mouse_allele_mods, :allele_name
    remove_column :mouse_allele_mods, :allele_mgi_accession_id
  end
end
class AddAlleleDescriptionToColony < ActiveRecord::Migration

  def self.up
    rename_column :colonies, :unwanted_allele_description, :allele_description
    add_column :colonies, :allele_description_summary, :text
    add_column :colonies, :auto_allele_description, :text
  end

  def self.down
    rename_column :colonies, :allele_description, :unwanted_allele_description
    remove_column :colonies, :allele_description_summary
    remove_column :colonies, :auto_allele_description
  end


end

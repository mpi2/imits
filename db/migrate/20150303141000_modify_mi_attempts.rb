class ModifyMiAttempts < ActiveRecord::Migration
  def self.up
    add_column :colonies, :mgi_allele_id, :string
    add_column :colonies, :allele_name, :string
  end

  def self.down
    remove_column :colonies, :mgi_allele_id
    remove_column :colonies, :allele_name
  end

end
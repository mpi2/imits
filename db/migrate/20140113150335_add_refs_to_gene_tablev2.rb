class AddRefsToGeneTablev2 < ActiveRecord::Migration

  def self.up
    rename_column :genes, :chromosome, :chr
    rename_column :genes, :strand, :strand_name

  end

  def self.down
    rename_column :genes, :chr, :chromosome
    rename_column :genes, :strand_name, :strand
  end
end

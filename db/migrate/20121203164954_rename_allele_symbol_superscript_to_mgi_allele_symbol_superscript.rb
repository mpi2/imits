class RenameAlleleSymbolSuperscriptToMgiAlleleSymbolSuperscript < ActiveRecord::Migration
  def self.up
    rename_column :targ_rep_es_cells, :allele_symbol_superscript, :mgi_allele_symbol_superscript
  end

  def self.down
    rename_column :targ_rep_es_cells, :mgi_allele_symbol_superscript, :allele_symbol_superscript
  end
end

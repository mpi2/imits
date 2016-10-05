class AddBetterMgiAlleleSymbolManagement < ActiveRecord::Migration

  def self.up
    add_column :colonies, :mgi_allele_symbol_without_impc_abbreviation, :boolean, :default => false

    sql = <<-EOF
      UPDATE colonies SET mgi_allele_symbol_without_impc_abbreviation = true, mgi_allele_symbol_superscript = allele_name
      WHERE colonies.allele_name IS NOT NULL AND colonies.allele_name LIKE 'em%'
    EOF

    ActiveRecord::Base.connection.execute(sql)
 
 end

 def self.down
    remove_column :colonies, :mgi_allele_symbol_without_impc_abbreviation
  end
end

class DropAlleleFieldsOnColonyTable < ActiveRecord::Migration

  def self.up

    sql = <<-EOF
      UPDATE alleles SET mgi_allele_symbol_superscript = colonies.allele_name, mgi_allele_symbol_without_impc_abbreviation = true
      FROM colonies
      WHERE colonies.id = alleles.colony_id AND colonies.allele_name IS NOT NULL AND colonies.allele_name != ''
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :colonies, :unwanted_allele
    remove_column :colonies, :allele_description
    remove_column :colonies, :mgi_allele_id
    remove_column :colonies, :allele_name
    remove_column :colonies, :mgi_allele_symbol_superscript
    remove_column :colonies, :allele_symbol_superscript_template
    remove_column :colonies, :allele_type
    remove_column :colonies, :allele_description_summary
    remove_column :colonies, :auto_allele_description       
  end


end

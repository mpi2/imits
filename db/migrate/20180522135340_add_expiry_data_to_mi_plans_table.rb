class AddExpiryDataToMiPlansTable < ActiveRecord::Migration
  def self.up
    add_column :mi_plans, :expiry_date, :date, default: false 

    sql = <<-EOF
      UPDATE mi_plans a SET crispr_legacy_data = true
        FROM colonies c, mi_attempts
        WHERE c.mi_attempt_id = mi_attempts.id AND a.colony_id = c.id AND (a.mutant_fa IS NULL OR a.mgi_allele_symbol_superscript IS NULL OR a.allele_type IS NULL OR a.allele_subtype IS NULL) AND mi_attempts.es_cell_id IS NULL;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :mi_plans, :expiry_date
  end
end

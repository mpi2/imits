class MoveVcfAnotationsToAlleleTable < ActiveRecord::Migration

  def self.up
    create_table :allele_annotations do |t|
      t.integer :allele_id, :null => false
      t.string :mod_type, :null => false
      t.string :chr, :null => false
      t.integer :start, :null => false
      t.integer :end, :null => false
      t.text :ref_seq, :null => true
      t.text :alt_seq, :null => true

      t.timestamps
    end

    sql = <<-EOF
      INSERT INTO allele_annotations(allele_id, mod_type, chr, start, "end", ref_seq, alt_seq, updated_at, created_at)
      SELECT alleles.id, trace_call_vcf_modifications.mod_type, trace_call_vcf_modifications.chr, trace_call_vcf_modifications.start, trace_call_vcf_modifications.end, trace_call_vcf_modifications.ref_seq, trace_call_vcf_modifications.alt_seq, trace_call_vcf_modifications.updated_at, trace_call_vcf_modifications.created_at 
        FROM trace_call_vcf_modifications
        JOIN trace_calls ON trace_calls.id = trace_call_vcf_modifications.trace_call_id
        JOIN alleles ON alleles.colony_id = trace_calls.colony_id
      ;
    EOF

    ActiveRecord::Base.connection.execute(sql)

  end

  def self.down
    drop_table :allele_annotations
  end

end

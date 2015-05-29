class CreateTraceCallVcfModifications < ActiveRecord::Migration
  def self.up
    create_table :trace_call_vcf_modifications do |t|
      t.integer :trace_call_id, :null => false
      t.string :mod_type, :null => false
      t.string :chr, :null => false
      t.integer :start, :null => false
      t.integer :end, :null => false
      t.text :ref_seq, :null => false
      t.text :alt_seq, :null => false

      t.timestamps
    end

    add_foreign_key :trace_call_vcf_modifications, :trace_calls, :column => :trace_call_id, :name => 'trace_call_vcf_modifications_trace_calls_fk'
  end

  def self.down
    drop_table :trace_call_vcf_modifications
  end
end

class ModifyTraceCall < ActiveRecord::Migration
  def self.up
    add_column :trace_calls, :exon_id, :string
  end

  def self.down
    remove_column :trace_calls, :exon_id
  end

end
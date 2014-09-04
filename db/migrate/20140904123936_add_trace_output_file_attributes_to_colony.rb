class AddTraceOutputFileAttributesToColony < ActiveRecord::Migration
  def change
    add_column :colonies, :file_trace_output, :text
    add_column :colonies, :file_trace_error, :text
    add_column :colonies, :file_exception_details, :text
    add_column :colonies, :file_return_code, :integer
    add_column :colonies, :is_het, :boolean, :default => false
  end
end

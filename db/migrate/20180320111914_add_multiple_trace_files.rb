class AddMultipleTraceFiles < ActiveRecord::Migration
  def self.up
    rename_table  :trace_files, :traces
    rename_column :traces, :trace_call_id, :trace_file_id

    rename_table  :trace_calls, :trace_files
    rename_column :trace_files, :trace_file_file_name, :trace_file_name
    rename_column :trace_files, :trace_file_content_type, :trace_content_type
    rename_column :trace_files, :trace_file_file_size, :trace_file_size
    rename_column :trace_files, :trace_file_updated_at, :trace_updated_at


    remove_column :trace_files, :file_alignment
    remove_column :trace_files, :file_filtered_analysis_vcf
    remove_column :trace_files, :file_variant_effect_output_txt
    remove_column :trace_files, :file_reference_fa
    remove_column :trace_files, :file_mutant_fa
    remove_column :trace_files, :file_primer_reads_fa
    remove_column :trace_files, :file_alignment_data_yaml
    remove_column :trace_files, :file_trace_output
    remove_column :trace_files, :file_trace_error
    remove_column :trace_files, :file_exception_details
    remove_column :trace_files, :file_return_code
    remove_column :trace_files, :file_merged_variants_vcf
    remove_column :trace_files, :exon_id

  end
end

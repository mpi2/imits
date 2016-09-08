class AllowUploadMultipleTraceFiles < ActiveRecord::Migration

  def self.up
    rename_table  :trace_files, :traces
    rename_column :traces, :trace_call_id, :trace_file_id

    rename_table  :trace_calls, :trace_files
    rename_column :trace_files, :trace_file_file_name, :trace_file_name
    rename_column :trace_files, :trace_file_content_type, :trace_content_type
    rename_column :trace_files, :trace_file_file_size, :trace_file_size
    rename_column :trace_files, :trace_file_updated_at, :trace_updated_at
    add_column    :trace_files, :mutagenesis_factor_id, :integer


    create_table :trace_calls do |t|
      t.integer :colony_id, :null => false
      t.integer :mutagenesis_factor_id, :null => false
      t.text    :file_alignment
      t.text    :file_filtered_analysis_vcf
      t.text    :file_variant_effect_output_txt
      t.text    :file_reference_fa
      t.text    :file_mutant_fa
      t.text    :file_primer_reads_fa
      t.text    :file_alignment_data_yaml
      t.text    :file_trace_output
      t.text    :file_trace_error
      t.text    :file_exception_details
      t.integer :file_return_code
      t.text    :file_merged_variants_vcf
      t.string :exon_id
      t.timestamps
    end

    sql = <<-EOF
      INSERT INTO trace_calls(
        colony_id, mutagenesis_factor_id, file_alignment, file_filtered_analysis_vcf, file_variant_effect_output_txt, file_reference_fa, file_mutant_fa,
        file_primer_reads_fa, file_alignment_data_yaml, file_trace_output, file_trace_error, file_exception_details, file_return_code, file_merged_variants_vcf, 
        exon_id, created_at, updated_at
        )
      SELECT trace_files.colony_id, mi_attempts.mutagenesis_factor_id, trace_files.file_alignment, trace_files.file_filtered_analysis_vcf, trace_files.file_variant_effect_output_txt,
             trace_files.file_reference_fa, trace_files.file_mutant_fa, trace_files.file_primer_reads_fa, trace_files.file_alignment_data_yaml,
             trace_files.file_trace_output, trace_files.file_trace_error, trace_files.file_exception_details, trace_files.file_return_code,
             trace_files.file_merged_variants_vcf, trace_files.exon_id, trace_files.created_at, trace_files.updated_at
      FROM trace_files
        JOIN colonies ON colonies.id = trace_files.colony_id
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
      WHERE trace_files.file_trace_error IS NOT NULL;
      
      -----
      UPDATE trace_files SET mutagenesis_factor_id = mi_attempts.mutagenesis_factor_id
      FROM colonies, mi_attempts
      WHERE colonies.id = trace_files.colony_id AND mi_attempts.id = colonies.mi_attempt_id;
    EOF

    ActiveRecord::Base.connection.execute(sql)


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


  def self.down
    add_column :trace_files, :file_alignment, :text
    add_column :trace_files, :file_filtered_analysis_vcf, :text
    add_column :trace_files, :file_variant_effect_output_txt, :text
    add_column :trace_files, :file_reference_fa, :text
    add_column :trace_files, :file_mutant_fa, :text
    add_column :trace_files, :file_primer_reads_fa, :text
    add_column :trace_files, :file_alignment_data_yaml, :text
    add_column :trace_files, :file_trace_output, :text
    add_column :trace_files, :file_trace_error, :text
    add_column :trace_files, :file_exception_details, :text
    add_column :trace_files, :file_return_code, :text
    add_column :trace_files, :file_merged_variants_vcf, :text
    add_column :trace_files, :exon_id, :string


    rename_column :trace_files, :trace_file_updated_at, :trace_updated_at
    rename_column :trace_files, :trace_file_name, :trace_file_file_name
    rename_column :trace_files, :trace_content_type, :trace_file_content_type



    sql = <<-EOF
      UPDATE trace_files SET 
        file_alignment = trace_calls.file_alignment,
        file_filtered_analysis_vcf = trace_calls.file_filtered_analysis_vcf,
        file_variant_effect_output_txt = trace_calls.file_variant_effect_output_txt,
        file_reference_fa = trace_calls.file_reference_fa,
        file_mutant_fa = trace_calls.file_mutant_fa,
        file_primer_reads_fa = trace_calls.file_primer_reads_fa,
        file_alignment_data_yaml = trace_calls.file_alignment_data_yaml,
        file_trace_output = trace_calls.file_trace_output,
        file_trace_error = trace_calls.file_trace_error,
        file_exception_details = trace_calls.file_exception_details,
        file_return_code = trace_calls.file_return_code,
        file_merged_variants_vcf = trace_calls.file_merged_variants_vcf,
        exon_id = trace_calls.exon_id
      FROM trace_calls
      WHERE trace_calls.colony_id = trace_files.colony_id;   
    EOF

    ActiveRecord::Base.connection.execute(sql)


    remove_column :trace_files, :mutagenesis_factor_id

    drop_table :trace_calls 
    rename_table  :trace_files, :trace_calls

    rename_column :traces, :trace_file_id, :trace_call_id
    rename_table  :traces, :trace_files
  end
end

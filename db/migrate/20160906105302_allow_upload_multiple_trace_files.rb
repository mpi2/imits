class UploadMultipleTraceFiles < ActiveRecord::Migration

  def self.up
    rename_table  :trace_files, :traces
    rename_column :traces, :trace_call_id, :trace_file_id

    rename_table  :trace_calls, :trace_files
    rename_column :trace_files, :trace_file_file_name, :trace_file_name
    rename_column :trace_files, :trace_file_content_type, :trace_content_type
    rename_column :trace_files, :trace_file_file_size, :trace_file_size
    rename_column :trace_files, :trace_file_updated_at, :trace_updated_at
    add_column    :trace_files, :allele_id, :integer

    create_table :mutagenesis_alleles do |t|
      t.integer :allele_id, :null => false
      t.integer :mutagenesis_factor_id, :null => false
    end

    sql = <<-EOF


      ----
      INSERT INTO mutagenesis_alleles(allele_id, mutagenesis_factor_id)
      SELECT alleles.id, mi_attempts.mutagenesis_factor_id
      FROM alleles
        JOIN colonies ON colonies.id = alleles.colony_id
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id AND mi_attempts.mutagenesis_factor_id IS NOT NULL
      ;


      UPDATE trace_files SET allele_id = alleles.id
      FROM colonies, alleles
      WHERE colonies.id = trace_files.colony_id AND alleles.colony_id = colonies.id
      ;

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
    remove_column :trace_files, :colony_id



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

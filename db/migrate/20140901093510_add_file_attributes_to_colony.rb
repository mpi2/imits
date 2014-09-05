class AddFileAttributesToColony < ActiveRecord::Migration
  def change
    add_column :colonies, :file_alignment, :text
    add_column :colonies, :file_filtered_analysis_vcf, :text
    add_column :colonies, :file_variant_effect_output_txt, :text
    add_column :colonies, :file_reference_fa, :text
    add_column :colonies, :file_mutant_fa, :text
    add_column :colonies, :file_primer_reads_fa, :text
    add_column :colonies, :file_alignment_data_yaml, :text
    #add_column :colonies, :file_trace_output, :text
    #add_column :colonies, :file_trace_error, :text
   # add_column :colonies, :file_exception_details, :text
    #add_column :colonies, :file_return_code, :integer
   # add_column :colonies, :file_merged_variants_vcf, :integer
   # add_column :colonies, :is_het, :boolean, :default => false
  end
end

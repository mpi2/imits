class AddFileAttributesToColony < ActiveRecord::Migration
  def change
    add_column :colonies, :file_alignment, :text
    add_column :colonies, :file_filtered_analysis_vcf, :text
    add_column :colonies, :file_variant_effect_output_txt, :text
    add_column :colonies, :file_reference_fa, :text
    add_column :colonies, :file_mutant_fa, :text
    add_column :colonies, :file_primer_reads_fa, :text
    add_column :colonies, :file_alignment_data_yaml, :text
  end
end

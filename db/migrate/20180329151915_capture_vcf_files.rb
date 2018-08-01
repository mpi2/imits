class CaptureVcfFiles < ActiveRecord::Migration
  def self.up
    add_column :alleles, :bam_file, :bytea
    add_column :alleles, :bam_file_index, :bytea
    add_column :alleles, :vcf_file, :bytea
    add_column :alleles, :vcf_file_index, :bytea

    drop_table :trace_call_vcf_modifications
    add_column :allele_annotations, :dup_coords, :string
    add_column :allele_annotations, :linked_concequence, :text 
    add_column :allele_annotations, :downstream_of_stop, :boolean, :defalut => false
    add_column :allele_annotations, :stop_gained, :boolean, :defalut => false
    add_column :allele_annotations, :consequence, :json

    sql = <<-EOF
      DELETE FROM allele_annotations;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end
end

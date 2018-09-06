class CaptureVcfFiles < ActiveRecord::Migration
  def self.up
    add_column :alleles, :bam_file, :bytea
    add_column :alleles, :bam_file_index, :bytea
    add_column :alleles, :vcf_file, :bytea
    add_column :alleles, :vcf_file_index, :bytea

    drop_table :trace_call_vcf_modifications

    add_column :allele_annotations, :exdels, :string
    add_column :allele_annotations, :partial_exdels, :string
    add_column :allele_annotations, :txc, :string
    add_column :allele_annotations, :splice_donor, :boolean, :defalut => false
    add_column :allele_annotations, :splice_acceptor, :boolean, :defalut => false
    add_column :allele_annotations, :protein_coding_region, :boolean, :defalut => false
    add_column :allele_annotations, :intronic, :boolean, :defalut => false
    add_column :allele_annotations, :frameshift, :boolean, :defalut => false
    add_column :allele_annotations, :linked_concequence, :text 
    add_column :allele_annotations, :downstream_of_stop, :boolean, :defalut => false
    add_column :allele_annotations, :stop_gained, :boolean, :defalut => false
    add_column :allele_annotations, :amino_acid, :text

    sql = <<-EOF
      DELETE FROM allele_annotations;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end
end

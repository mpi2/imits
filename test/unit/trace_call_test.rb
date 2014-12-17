require 'test_helper'

class TraceCallTest < ActiveSupport::TestCase
  context 'TraceCall' do
    context "relationships" do
      should "belong to a colony" do
        belong_to :colony
      end
    end

    context "db columns" do
      should have_db_column(:colony_id).of_type(:integer).with_options(:null => false)
      should have_db_column(:file_alignment).of_type(:text)
      should have_db_column(:file_filtered_analysis_vcf).of_type(:text)
      should have_db_column(:file_variant_effect_output_txt).of_type(:text)
      should have_db_column(:file_reference_fa).of_type(:text)
      should have_db_column(:file_mutant_fa).of_type(:text)
      should have_db_column(:file_primer_reads_fa).of_type(:text)
      should have_db_column(:file_alignment_data_yaml).of_type(:text)
      should have_db_column(:file_trace_output).of_type(:text)
      should have_db_column(:file_trace_error).of_type(:text)
      should have_db_column(:file_exception_details).of_type(:text)
      should have_db_column(:file_return_code).of_type(:integer)
      should have_db_column(:file_merged_variants_vcf).of_type(:text)
      should have_db_column(:is_het).of_type(:boolean)
      should have_db_column(:created_at).of_type(:datetime).with_options(:null => false)
      should have_db_column(:updated_at).of_type(:datetime).with_options(:null => false)
      should have_db_column(:trace_file_file_name).of_type(:string)
      should have_db_column(:trace_file_content_type).of_type(:string)
      should have_db_column(:trace_file_file_size).of_type(:integer)
      should have_db_column(:trace_file_updated_at).of_type(:datetime)
    end
  end
end

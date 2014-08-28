require 'test_helper'

class ColonyTest < ActiveSupport::TestCase
    context 'Colony' do
        context "validations" do
            should "have a name" do
                validate_presence_of :name
            end
        end

        context "relationships" do
            should "belong to an mi_attempt" do
                belong_to :mi_attempt
            end

            should "have one colony qc" do
                have_one(:colony_qc)
            end

            should "allow nested attributes for colony_qc" do
                accept_nested_attributes_for(:colony_qc)
            end
        end

        context "db columns" do
            should 'have' do
                should have_db_column(:name).of_type(:string).with_options(:null => false)
                should have_db_column(:mi_attempt_id).of_type(:integer)
                should have_db_column(:genotype_confirmed).of_type(:boolean).with_options(:default => false)
                should have_db_column(:trace_file_file_name).of_type(:string)
                should have_db_column(:trace_file_content_type).of_type(:string)
                should have_db_column(:trace_file_file_size).of_type(:integer)
                should have_db_column(:trace_file_updated_at).of_type(:datetime)
                should have_db_column(:genotype_confirmed).of_type(:boolean)
            end
        end

        context 'creation of qc' do
            context 'for crispr mi s' do
                should 'be able to create qc via attributes' do
                # crisprs can have multiple colonies
                    mi = Factory.create :mi_attempt_crispr, :colonies_attributes => [{ :name => 'test_colony', :genotype_confirmed => true, :colony_qc_attributes => {
                        :qc_southern_blot => 'pass',
                        :qc_five_prime_lr_pcr => 'pass',
                        :qc_five_prime_cassette_integrity => 'pass',
                        :qc_tv_backbone_assay => 'pass',
                        :qc_neo_count_qpcr => 'pass',
                        :qc_lacz_count_qpcr => 'pass',
                        :qc_neo_sr_pcr => 'pass',
                        :qc_loa_qpcr => 'pass',
                        :qc_homozygous_loa_sr_pcr => 'pass',
                        :qc_lacz_sr_pcr => 'pass',
                        :qc_mutant_specific_sr_pcr => 'pass',
                        :qc_loxp_confirmation => 'pass',
                        :qc_three_prime_lr_pcr => 'pass',
                        :qc_critical_region_qpcr => 'pass',
                        :qc_loxp_srpcr => 'pass',
                        :qc_loxp_srpcr_and_sequencing => 'pass'
                    } }]
                    assert_false mi.colonies.first.blank?
                    assert_false mi.colonies.first.colony_qc.blank?
                   assert_equal 'pass', mi.colonies.first.colony_qc.qc_southern_blot
                end
            end
        end
    end
end

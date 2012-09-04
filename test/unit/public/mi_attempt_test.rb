# encoding: utf-8

require 'test_helper'

class Public::MiAttemptTest < ActiveSupport::TestCase
  context 'Public::MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create(:mi_attempt).to_public
    end

    should 'have #status_name' do
      assert_equal default_mi_attempt.status_name, default_mi_attempt.status.name
    end

    should 'limit the public mass-assignment API' do
      expected = %w{
        es_cell_name
        mi_date
        colony_name
        consortium_name
        production_centre_name
        distribution_centres_attributes
        blast_strain_name
        total_blasts_injected
        total_transferred
        number_surrogates_receiving
        total_pups_born
        total_female_chimeras
        total_male_chimeras
        total_chimeras
        number_of_males_with_0_to_39_percent_chimerism
        number_of_males_with_40_to_79_percent_chimerism
        number_of_males_with_80_to_99_percent_chimerism
        number_of_males_with_100_percent_chimerism
        colony_background_strain_name
        test_cross_strain_name
        date_chimeras_mated
        number_of_chimera_matings_attempted
        number_of_chimera_matings_successful
        number_of_chimeras_with_glt_from_cct
        number_of_chimeras_with_glt_from_genotyping
        number_of_chimeras_with_0_to_9_percent_glt
        number_of_chimeras_with_10_to_49_percent_glt
        number_of_chimeras_with_50_to_99_percent_glt
        number_of_chimeras_with_100_percent_glt
        total_f1_mice_from_matings
        number_of_cct_offspring
        number_of_het_offspring
        number_of_live_glt_offspring
        mouse_allele_type
        qc_southern_blot_result
        qc_five_prime_lr_pcr_result
        qc_five_prime_cassette_integrity_result
        qc_tv_backbone_assay_result
        qc_neo_count_qpcr_result
        qc_neo_sr_pcr_result
        qc_loa_qpcr_result
        qc_homozygous_loa_sr_pcr_result
        qc_lacz_sr_pcr_result
        qc_mutant_specific_sr_pcr_result
        qc_loxp_confirmation_result
        qc_three_prime_lr_pcr_result
        report_to_public
        is_active
        is_released_from_genotyping
        comments
        genotyping_comment
      }
      got = (Public::MiAttempt.accessible_attributes.to_a - ['audit_comment'])
      assert_equal expected.sort, got.sort, "Unexpected: #{got - expected}; Not got: #{expected - got}"
    end

    should 'have defined attributes in serialized output' do
      expected = %w{
        id
        es_cell_name
        es_cell_marker_symbol
        es_cell_allele_symbol
        mi_date
        status_name
        colony_name
        consortium_name
        production_centre_name
        distribution_centres_attributes
        pretty_print_distribution_centres
        blast_strain_name
        total_blasts_injected
        total_transferred
        number_surrogates_receiving
        total_pups_born
        total_female_chimeras
        total_male_chimeras
        total_chimeras
        number_of_males_with_0_to_39_percent_chimerism
        number_of_males_with_40_to_79_percent_chimerism
        number_of_males_with_80_to_99_percent_chimerism
        number_of_males_with_100_percent_chimerism
        colony_background_strain_name
        test_cross_strain_name
        date_chimeras_mated
        number_of_chimera_matings_attempted
        number_of_chimera_matings_successful
        number_of_chimeras_with_glt_from_cct
        number_of_chimeras_with_glt_from_genotyping
        number_of_chimeras_with_0_to_9_percent_glt
        number_of_chimeras_with_10_to_49_percent_glt
        number_of_chimeras_with_50_to_99_percent_glt
        number_of_chimeras_with_100_percent_glt
        total_f1_mice_from_matings
        number_of_cct_offspring
        number_of_het_offspring
        number_of_live_glt_offspring
        mouse_allele_type
        mouse_allele_symbol_superscript
        mouse_allele_symbol
        qc_southern_blot_result
        qc_five_prime_lr_pcr_result
        qc_five_prime_cassette_integrity_result
        qc_tv_backbone_assay_result
        qc_neo_count_qpcr_result
        qc_neo_sr_pcr_result
        qc_loa_qpcr_result
        qc_homozygous_loa_sr_pcr_result
        qc_lacz_sr_pcr_result
        qc_mutant_specific_sr_pcr_result
        qc_loxp_confirmation_result
        qc_three_prime_lr_pcr_result
        report_to_public
        is_active
        is_released_from_genotyping
        comments
        mi_plan_id
        genotyping_comment
        phenotype_attempts_count
        pipeline_name
      }
      got = default_mi_attempt.as_json.keys
      assert_equal expected.sort, got.sort, "Unexpected: #{got - expected}; Not got: #{expected - got}"
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { default_mi_attempt.as_json(nil) }
      end
    end

    context '#to_xml' do
      should 'work the same as #as_json' do
        doc = Nokogiri::XML(default_mi_attempt.to_xml)
        assert_equal default_mi_attempt.status.name, doc.css('status_name').text
      end

      should 'output each attribute only once' do
        doc = Nokogiri::XML(default_mi_attempt.to_xml)
        assert_equal 1, doc.xpath('count(//id)').to_i
      end
    end

    context '#distribution_centres_attributes' do
      should 'be output correctly' do
        mi = Factory.create(:mi_attempt_genotype_confirmed)
        ds1 = Factory.create(:mi_attempt_distribution_centre,
          :start_date => '2012-01-02', :mi_attempt => mi)
        ds2 = Factory.create(:mi_attempt_distribution_centre,
          :end_date => '2012-02-02', :mi_attempt => mi)

        expected = [
          ds1.as_json,
          ds2.as_json
        ]

        mi = mi.reload.to_public
        assert_equal expected, mi.distribution_centres_attributes
      end

      should 'can be updated and destroyed' do
        mi = Factory.create(:mi_attempt_genotype_confirmed).to_public
        ds1 = Factory.create(:mi_attempt_distribution_centre,
          :centre => Centre.find_by_name!('WTSI'),
          :start_date => '2012-01-02', :mi_attempt => mi)
        ds2 = Factory.create(:mi_attempt_distribution_centre,
          :end_date => '2012-02-02', :mi_attempt => mi)

        mi = mi.reload
        attrs = mi.distribution_centres_attributes
        attrs[0]['centre_name'] = 'ICS'
        attrs[1][:_destroy] = true
        mi.update_attributes!(:distribution_centres_attributes => attrs)

        assert_nil MiAttempt::DistributionCentre.find_by_id(ds2.id)
        ds1.reload
        assert_equal 'ICS', ds1.centre_name
      end
    end

    should 'have #phenotype_attempts_count' do
      set_mi_attempt_genotype_confirmed(default_mi_attempt)
      Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
      Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
      default_mi_attempt.reload
      assert_equal 2, default_mi_attempt.phenotype_attempts_count
    end

    should 'have #pipeline_name' do
      set_mi_attempt_genotype_confirmed(default_mi_attempt)
      Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
      Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
      default_mi_attempt.reload
      assert_match(/Auto-generated Pipeline Name/, default_mi_attempt.pipeline_name)
    end

  end
end

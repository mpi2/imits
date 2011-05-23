# encoding: utf-8

require 'test_helper'

class Kermits2::MigrationTest < ActiveSupport::TestCase

  context 'Kermits2::Migration' do
    setup do
      Pipeline.destroy_all
      Centre.destroy_all
      assert_equal 0, MiAttempt.count
    end

    should 'migrate across centres' do
      Kermits2::Migration.run(:mi_attempt_ids => [])

      assert_equal 8, Centre.count
      centre_names = Centre.all.collect(&:name)
      assert_include centre_names, 'ICS'
      assert_include centre_names, 'WTSI'
      assert_include centre_names, 'Monterotondo'
    end

    should 'migrate across pipelines' do
      Kermits2::Migration.run(:mi_attempt_ids => [])

      assert_equal 5, Pipeline.count
      assert_equal 'EUCOMM consortia', Pipeline.find_by_name('EUCOMM').description
      assert_equal 'TIGM Gene trap resource', Pipeline.find_by_name('TIGM').description
      assert_equal 0, Clone.count
    end

    context 'migrating an mi attempt' do

      should 'create clone using data from marts if it does not already exist' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029])
        assert_equal 1, MiAttempt.count
        assert_equal 1, Clone.count

        mi_attempt = MiAttempt.first
        clone = mi_attempt.clone

        assert_equal 'EPD0127_4_E01', clone.clone_name
      end

      should 'create 2 mi attempts of the same clone' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029, 11101])
        assert_equal 2, MiAttempt.count
      end

      should 'import gene trap clones from the old DB data when mart data does not exist' do
        Kermits2::Migration.run(:mi_attempt_ids => [3775])
        assert_equal 1, MiAttempt.count
        clone = MiAttempt.first.clone
        assert_equal 'EUC0018f04', clone.clone_name
        assert_equal 'Eed', clone.marker_symbol
        assert_nil clone.allele_name_superscript_template
        assert_nil clone.allele_type
        assert_nil clone.mgi_accession_id
      end

      should 'import faculty line clones from the old DB data when mart data does not exist' do
        Kermits2::Migration.run(:mi_attempt_ids => [7330])
        assert_equal 1, MiAttempt.count
        clone = MiAttempt.first.clone
        assert_equal 'EPD0122_6_C07', clone.clone_name
        assert_equal 'Ptchd2', clone.marker_symbol
        assert_equal 'tm1a(KOMP)Wtsi', clone.allele_name_superscript
        assert_nil clone.mgi_accession_id
      end

      should 'migrate its centres' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029])
        assert_equal 1, MiAttempt.count
        mi_attempt = MiAttempt.first

        assert_equal 'WTSI', mi_attempt.production_centre.name
        assert_equal 'CNB', mi_attempt.distribution_centre.name
      end

      should 'migrate numeric fields' do
        old_mi_attempts = Old::MiAttempt.find(5268, 3973, 7335, 11785)
        assert_not_empty old_mi_attempts

        Kermits2::Migration.run(:mi_attempt_ids => [5268, 3973, 7335, 11785])
        assert_equal 4, MiAttempt.count
        assert_equal 4, Clone.count

        mi_5268, mi_3973, mi_7335, mi_11785 = MiAttempt.find(:all, :order => 'id asc')

        # Transfer details
        assert_equal 40, mi_5268.total_blasts_injected
        assert_equal 80, mi_5268.total_transferred
        assert_equal nil, mi_5268.number_surrogates_receiving

        # Litter details
        assert_equal 23, mi_3973.total_pups_born
        assert_equal 4, mi_3973.total_female_chimeras
        assert_equal 7, mi_3973.total_male_chimeras
        assert_equal 11, mi_3973.total_chimeras
        assert_equal 0, mi_3973.number_of_males_with_100_percent_chimerism
        assert_equal 1, mi_3973.number_of_males_with_80_to_99_percent_chimerism
        assert_equal 2, mi_3973.number_of_males_with_40_to_79_percent_chimerism
        assert_equal 4, mi_3973.number_of_males_with_0_to_39_percent_chimerism

        # Chimera mating details
        assert_equal 7, mi_7335.number_of_chimera_matings_attempted
        assert_equal 4, mi_7335.number_of_chimera_matings_successful
        assert_equal 0, mi_7335.number_of_chimeras_with_glt_from_cct
        assert_equal 16,  mi_7335.number_of_chimeras_with_glt_from_genotyping
        assert_equal 2, mi_11785.number_of_chimeras_with_0_to_9_percent_glt
        assert_equal 1, mi_11785.number_of_chimeras_with_10_to_49_percent_glt
        assert_equal 1, mi_11785.number_of_chimeras_with_50_to_99_percent_glt
        assert_equal 0, mi_11785.number_of_chimeras_with_100_percent_glt
        assert_equal 175, mi_11785.total_f1_mice_from_matings
        assert_equal 16, mi_11785.number_of_cct_offspring
        assert_equal 24, mi_11785.number_of_het_offspring
        assert_equal 21, mi_11785.number_of_live_glt_offspring
      end

      def migrate_mi(mi_id)
        old_mi_attempts = Old::MiAttempt.find(mi_id)
        assert_not_nil old_mi_attempts

        Kermits2::Migration.run(:mi_attempt_ids => [mi_id])
        assert_equal 1, MiAttempt.count
        assert_equal 1, Clone.count

        MiAttempt.first
      end

      should 'migrate colony name' do
        assert_equal 'MAJV', migrate_mi(5268).colony_name
      end

      should 'migrate emma status' do
        assert_equal :unsuitable_sticky, migrate_mi(5268).emma_status
      end

      should 'migrate mi_date' do
        assert_equal Date.parse('2008-01-21'), migrate_mi(5268).mi_date
      end

      should 'migrate date_chimeras_mated' do
        assert_equal Date.parse('2008-08-06'), migrate_mi(3973).date_chimeras_mated
      end

      should 'migrate miscellaneous booleans' do
        mi = migrate_mi(12211)
        assert_equal [true, false, false],
                [mi.is_active, mi.should_export_to_mart, mi.is_released_from_genotyping]
      end

      should 'migrate QC fields none of which are set to null' do
        mi = migrate_mi(3720)

        expected = {
          'qc_southern_blot' => 'na',
          'qc_five_prime_lr_pcr' => 'na',
          'qc_five_prime_cassette_integrity' => 'na',
          'qc_tv_backbone_assay' => 'na',
          'qc_neo_count_qpcr' => 'pass',
          'qc_neo_sr_pcr' => 'na',
          'qc_loa_qpcr' => 'fail',
          'qc_homozygous_loa_sr_pcr' => 'na',
          'qc_lacz_sr_pcr' => 'na',
          'qc_mutant_specific_sr_pcr' => 'na',
          'qc_loxp_confirmation' => 'na',
          'qc_three_prime_lr_pcr' => 'na'
        }

        wrong = {}
        expected.each do |name, value|
          actual_value = mi.send(name).try(:description)
          wrong[name] = actual_value if(actual_value != value)
        end

        assert wrong.empty?, "Incorrect QC fields: #{wrong.inspect}"
      end

      should 'migrate QC fields that are null as "na"' do
        mi = migrate_mi(3705)

        expected = {
          'qc_southern_blot' => 'na',
          'qc_five_prime_lr_pcr' => 'na',
          'qc_five_prime_cassette_integrity' => 'na',
          'qc_tv_backbone_assay' => 'na',
          'qc_neo_count_qpcr' => 'na',
          'qc_neo_sr_pcr' => 'na',
          'qc_loa_qpcr' => 'na',
          'qc_homozygous_loa_sr_pcr' => 'na',
          'qc_lacz_sr_pcr' => 'na',
          'qc_mutant_specific_sr_pcr' => 'na',
          'qc_loxp_confirmation' => 'na',
          'qc_three_prime_lr_pcr' => 'na'
        }

        wrong = {}
        expected.each do |name, value|
          actual_value = mi.send(name).try(:description)
          wrong[name] = actual_value if(actual_value != value)
        end

        assert wrong.empty?, "Incorrect QC fields: #{wrong.inspect}"
      end

      context 'status' do
        should 'migrate when originally "Genotype confirmed"' do
          assert_equal MiAttemptStatus.genotype_confirmed.description, migrate_mi(3702).mi_attempt_status.description
        end

        should 'migrate non-genotype confirmed statuses like "Chimera mating complete" to "Micro-injection in progress"' do
          assert_equal MiAttemptStatus.micro_injection_in_progress, migrate_mi(11737).mi_attempt_status
        end

        should 'migrate non-genotype confirmed statuses like "Failed Attempt" to "Micro-injection in progress"' do
          assert_equal MiAttemptStatus.micro_injection_in_progress, migrate_mi(3987).mi_attempt_status
        end
      end

    end # context 'migrating an mi attempt'

  end
end

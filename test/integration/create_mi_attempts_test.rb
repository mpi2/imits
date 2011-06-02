# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'Create MI Attempt' do

    should 'require login' do
      visit '/'
      assert page.has_no_css? '#mainnav a:contains("Create")'
    end

    should 'work' do
      centre = Factory.create :centre, :name => 'Test Centre'
      user = Factory.create :user, :production_centre => centre
      Factory.create :clone, :clone_name => 'EPD_CREATE_MI'

      login user.email
      click_link 'Create'

      assert_equal 0, MiAttempt.count

      fill_in 'mi_attempt[colony_name]', :with => 'ABCD'
      select 'WTSI', :from => 'mi_attempt[distribution_centre_id]'
      select 'ICS', :from => 'mi_attempt[production_centre_id]'

      fill_in 'mi_attempt[total_blasts_injected]', :with => 10
      fill_in 'mi_attempt[total_transferred]', :with => 9
      fill_in 'mi_attempt[number_surrogates_receiving]', :with => 8

      fill_in 'mi_attempt[total_pups_born]', :with => 16
      fill_in 'mi_attempt[total_female_chimeras]', :with => 3
      fill_in 'mi_attempt[total_male_chimeras]', :with => 10
      fill_in 'mi_attempt[number_of_males_with_0_to_39_percent_chimerism]', :with => 4
      fill_in 'mi_attempt[number_of_males_with_40_to_79_percent_chimerism]', :with => 3
      fill_in 'mi_attempt[number_of_males_with_80_to_99_percent_chimerism]', :with => 2
      fill_in 'mi_attempt[number_of_males_with_100_percent_chimerism]', :with => 1

      select 'Suitable for EMMA - STICKY', :from => 'mi_attempt[emma_status]'
      fill_in 'mi_attempt[number_of_chimera_matings_attempted]', :with => 42
      fill_in 'mi_attempt[number_of_chimera_matings_successful]', :with => 41
      fill_in 'mi_attempt[number_of_chimeras_with_glt_from_cct]', :with => 40
      fill_in 'mi_attempt[number_of_chimeras_with_glt_from_genotyping]', :with => 39
      fill_in 'mi_attempt[number_of_chimeras_with_0_to_9_percent_glt]', :with => 5
      fill_in 'mi_attempt[number_of_chimeras_with_10_to_49_percent_glt]', :with => 6
      fill_in 'mi_attempt[number_of_chimeras_with_50_to_99_percent_glt]', :with => 7
      fill_in 'mi_attempt[number_of_chimeras_with_100_percent_glt]', :with => 8
      fill_in 'mi_attempt[total_f1_mice_from_matings]', :with => 38
      fill_in 'mi_attempt[number_of_cct_offspring]', :with => 37
      fill_in 'mi_attempt[number_of_het_offspring]', :with => 36
      fill_in 'mi_attempt[number_of_live_glt_offspring]', :with => 35

      click_button 'mi_attempt_submit'
      sleep 6

      assert_equal 1, MiAttempt.count
      mi_attempt = MiAttempt.first
      assert_not_nil mi_attempt

      # Important fields
      # TODO clone
      assert_equal MiAttemptStatus.micro_injection_in_progress, mi_attempt.mi_attempt_status
      assert_equal 'ABCD', mi_attempt.colony_name
      assert_equal 'WTSI', mi_attempt.distribution_centre.name
      assert_equal 'ICS', mi_attempt.production_centre.name

      # Transfer details
      # TODO assert_equal 'something', mi_attempt.blast_strain
      assert_equal 10, mi_attempt.total_blasts_injected
      assert_equal 9, mi_attempt.total_transferred
      assert_equal 8, mi_attempt.number_surrogates_receiving

      # Litter details
      assert_equal 16, mi_attempt.total_pups_born
      assert_equal 3, mi_attempt.total_female_chimeras
      assert_equal 10, mi_attempt.total_male_chimeras
      assert_equal 4, mi_attempt.number_of_males_with_0_to_39_percent_chimerism
      assert_equal 3, mi_attempt.number_of_males_with_40_to_79_percent_chimerism
      assert_equal 2, mi_attempt.number_of_males_with_80_to_99_percent_chimerism
      assert_equal 1, mi_attempt.number_of_males_with_100_percent_chimerism

      # Chimera mating details
      assert_equal :suitable_sticky, mi_attempt.emma_status
      # TODO assert_equal something, mi_attempt.test_cross_strain
      # TODO assert_equal something, mi_attempt.colony_background_strain
      assert_equal 42, mi_attempt.number_of_chimera_matings_attempted
      assert_equal 41, mi_attempt.number_of_chimera_matings_successful
      assert_equal 40, mi_attempt.number_of_chimeras_with_glt_from_cct
      assert_equal 39, mi_attempt.number_of_chimeras_with_glt_from_genotyping
      assert_equal 5, mi_attempt.number_of_chimeras_with_0_to_9_percent_glt
      assert_equal 6, mi_attempt.number_of_chimeras_with_10_to_49_percent_glt
      assert_equal 7, mi_attempt.number_of_chimeras_with_50_to_99_percent_glt
      assert_equal 8, mi_attempt.number_of_chimeras_with_100_percent_glt
      assert_equal 38, mi_attempt.total_f1_mice_from_matings
      assert_equal 37, mi_attempt.number_of_cct_offspring
      assert_equal 36, mi_attempt.number_of_het_offspring
      assert_equal 35, mi_attempt.number_of_live_glt_offspring
      assert_equal 'e', mi_attempt.mouse_allele_type

      # QC details
      assert_equal 'pass', mi_attempt.qc_southern_blot.description
      assert_equal 'fail', mi_attempt.qc_five_prime_lr_pcr.description
      assert_equal 'pass', mi_attempt.qc_five_prime_cassette_integrity.description
      assert_equal 'fail', mi_attempt.qc_tv_backbone_assay.description
      assert_equal 'pass', mi_attempt.qc_neo_count_qpcr.description
      assert_equal 'fail', mi_attempt.qc_neo_sr_pcr.description
      assert_equal 'pass', mi_attempt.qc_loa_qpcr.description
      assert_equal 'fail', mi_attempt.qc_homozygous_loa_sr_pcr.description
      assert_equal 'pass', mi_attempt.qc_lacz_sr_pcr.description
      assert_equal 'fail', mi_attempt.qc_mutant_specific_sr_pcr.description
      assert_equal 'pass', mi_attempt.qc_loxp_confirmation.description
      assert_equal 'fail', mi_attempt.qc_three_prime_lr_pcr.description
      assert_false  mi_attempt.should_export_to_mart
      assert_false  mi_attempt.is_active
      assert_true mi_attempt.is_released_from_genotyping
    end

    should 'go to the right page after submit'

    should 'by default set all optional fields to blank or N/A, and fields with defaults to their defaults' do
      centre = Factory.create :centre, :name => 'Test Centre'
      user = Factory.create :user, :production_centre => centre
      Factory.create :clone, :clone_name => 'EPD_CREATE_MI'

      login user.email
      click_link 'Create'

      assert_equal 0, MiAttempt.count
      click_button 'mi_attempt_submit'
      sleep 6
      assert_equal 1, MiAttempt.count
      mi_attempt = MiAttempt.first
      assert_not_nil mi_attempt

      # Important fields
      # TODO clone
      assert_nil mi_attempt.mi_date
      assert_equal MiAttemptStatus.micro_injection_in_progress, mi_attempt.mi_attempt_status
      assert_nil mi_attempt.colony_name
      assert_equal 'Test Centre', mi_attempt.production_centre.name
      assert_equal 'Test Centre', mi_attempt.distribution_centre.name

      # Transfer details
      assert_nil mi_attempt.blast_strain
      assert_nil mi_attempt.total_blasts_injected
      assert_nil mi_attempt.total_transferred
      assert_nil mi_attempt.number_surrogates_receiving

      # Litter details
      assert_nil mi_attempt.total_pups_born
      assert_nil mi_attempt.total_female_chimeras
      assert_nil mi_attempt.total_male_chimeras
      assert_equal 0, mi_attempt.total_chimeras
      assert_nil mi_attempt.number_of_males_with_0_to_39_percent_chimerism
      assert_nil mi_attempt.number_of_males_with_40_to_79_percent_chimerism
      assert_nil mi_attempt.number_of_males_with_80_to_99_percent_chimerism
      assert_nil mi_attempt.number_of_males_with_100_percent_chimerism

      # Chimera mating details
      assert_equal :unsuitable, mi_attempt.emma_status
      assert_nil mi_attempt.test_cross_strain_id
      assert_nil mi_attempt.colony_background_strain_id
      assert_nil mi_attempt.date_chimeras_mated
      assert_nil mi_attempt.number_of_chimera_matings_attempted
      assert_nil mi_attempt.number_of_chimera_matings_successful
      assert_nil mi_attempt.number_of_chimeras_with_glt_from_cct
      assert_nil mi_attempt.number_of_chimeras_with_glt_from_genotyping
      assert_nil mi_attempt.number_of_chimeras_with_0_to_9_percent_glt
      assert_nil mi_attempt.number_of_chimeras_with_10_to_49_percent_glt
      assert_nil mi_attempt.number_of_chimeras_with_50_to_99_percent_glt
      assert_nil mi_attempt.number_of_chimeras_with_100_percent_glt
      assert_nil mi_attempt.total_f1_mice_from_matings
      assert_nil mi_attempt.number_of_cct_offspring
      assert_nil mi_attempt.number_of_het_offspring
      assert_nil mi_attempt.number_of_live_glt_offspring
      assert_nil mi_attempt.mouse_allele_type

      # QC details
      assert_equal 'na', mi_attempt.qc_southern_blot.description
      assert_equal 'na', mi_attempt.qc_five_prime_lr_pcr.description
      assert_equal 'na', mi_attempt.qc_five_prime_cassette_integrity.description
      assert_equal 'na', mi_attempt.qc_tv_backbone_assay.description
      assert_equal 'na', mi_attempt.qc_neo_count_qpcr.description
      assert_equal 'na', mi_attempt.qc_neo_sr_pcr.description
      assert_equal 'na', mi_attempt.qc_loa_qpcr.description
      assert_equal 'na', mi_attempt.qc_homozygous_loa_sr_pcr.description
      assert_equal 'na', mi_attempt.qc_lacz_sr_pcr.description
      assert_equal 'na', mi_attempt.qc_mutant_specific_sr_pcr.description
      assert_equal 'na', mi_attempt.qc_loxp_confirmation.description
      assert_equal 'na', mi_attempt.qc_three_prime_lr_pcr.description
      assert_true  mi_attempt.should_export_to_mart
      assert_true  mi_attempt.is_active
      assert_false mi_attempt.is_released_from_genotyping
    end

  end
end

# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'Create MI Attempt' do

    setup do
      Factory.create :clone, :clone_name => 'EPD_CREATE_MI',
              :marker_symbol => 'Cbx1', :is_in_targ_rep => true
    end

    should 'require login' do
      visit '/'
      assert page.has_no_css? '#mainnav a:contains("Create")'
    end

    should 'not show any other fields while a clone is not selected' do
      login
      click_link 'Create'
      assert_false page.find('input[type=submit]').visible?
      assert_false page.find('input[name="mi_attempt[total_blasts_injected]"]').visible?
    end

    context 'when choosing from all clones' do
      should 'only list those in targ_rep' do
        Factory.create :clone, :clone_name => 'EPD9999_Z_Z01', :is_in_targ_rep => true
        Factory.create :clone, :clone_name => 'EPD9999_Z_Z02', :is_in_targ_rep => true
        Factory.create :clone, :clone_name => 'EPD9999_Z_Z03', :is_in_targ_rep => false

        login
        click_link 'Create'

        find('#mi_attempt_clone_id ~ .x-form-arrow-trigger').click
        texts = all('.x-combo-list-item').map(&:text)
        assert_not_include texts, 'EPD9999_Z_Z03'
        assert_equal 3, texts.size
      end

      should 'not have any clone selected by default' do
        login
        click_link 'Create'

        assert_blank page.find('#mi_attempt_clone_id ~ input[type=text]').value
        assert_blank page.find('#mi_attempt_clone_id').value
      end
    end

    context 'when choosing by gene and then its clones' do
      setup do
        Factory.create :clone, :clone_name => 'EPD_NOT_IN_TARG_REP', :is_in_targ_rep => false
        login
        click_link 'Create'
      end

      should 'only list genes for clones in targ rep' do
        find('#gene-combo ~ .x-form-arrow-trigger').click
        texts = all('.x-combo-list-item').map(&:text)
        assert_equal ['[All]', 'Cbx1'], texts
      end

      should 'not have all gene symbols selected by default' do
        assert_equal '[All]', find('input#gene-combo').value
      end

      should 'limit list of clones to the selected gene symbol' do
        create_common_test_objects
        Factory.create :clone, :clone_name => 'EPD0127_4_E01_DUPLICATE', :marker_symbol => 'Trafd1'
        click_link 'Create'
        find('#gene-combo ~ .x-form-arrow-trigger').click
        find('.x-combo-list-item', :text => 'Trafd1').click
        find('#mi_attempt_clone_id ~ .x-form-arrow-trigger').click
        within('div.x-combo-list ~ div.x-combo-list') do
          texts = all('.x-combo-list-item').map(&:text)
          assert_equal ['EPD0127_4_E01', 'EPD0127_4_E01_DUPLICATE'], texts
        end
      end
    end

    should 'work' do
      assert_equal 0, MiAttempt.count

      create_common_test_objects
      Factory.create :clone, :marker_symbol => 'Cbx7', :clone_name => 'EPD0013_1_B05'
      clone = Factory.create :clone, :marker_symbol => 'Cbx7', :clone_name => 'EPD0013_1_F05'

      centre = Factory.create :centre, :name => 'Test Centre'
      user = Factory.create :user, :production_centre => centre

      login user.email
      click_link 'Create'

      find('#gene-combo ~ .x-form-arrow-trigger').click
      find('.x-combo-list-item', :text => 'Cbx7').click
      find('#mi_attempt_clone_id ~ .x-form-arrow-trigger').click
      find('div.x-combo-list ~ div.x-combo-list .x-combo-list-item', :text => 'EPD0013_1_F05').click

      fill_in 'mi_attempt[colony_name]', :with => 'ABCD'
      select 'WTSI', :from => 'mi_attempt[distribution_centre_id]'
      select 'ICS', :from => 'mi_attempt[production_centre_id]'

      select 'Swiss Webster', :from => 'mi_attempt[blast_strain_id]'
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
      select '129S5', :from => 'mi_attempt[test_cross_strain_id]'
      select 'B6JTyr<c-Brd>', :from => 'mi_attempt[colony_background_strain_id]'
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
      select MiAttempt::MOUSE_ALLELE_OPTIONS.last[1], :from => 'mi_attempt[mouse_allele_type]'

      select 'pass', :from => 'mi_attempt[qc_southern_blot_id]'
      select 'fail', :from => 'mi_attempt[qc_five_prime_lr_pcr_id]'
      select 'pass', :from => 'mi_attempt[qc_five_prime_cassette_integrity_id]'
      select 'fail', :from => 'mi_attempt[qc_tv_backbone_assay_id]'
      select 'pass', :from => 'mi_attempt[qc_neo_count_qpcr_id]'
      select 'fail', :from => 'mi_attempt[qc_neo_sr_pcr_id]'
      select 'pass', :from => 'mi_attempt[qc_loa_qpcr_id]'
      select 'fail', :from => 'mi_attempt[qc_homozygous_loa_sr_pcr_id]'
      select 'pass', :from => 'mi_attempt[qc_lacz_sr_pcr_id]'
      select 'fail', :from => 'mi_attempt[qc_mutant_specific_sr_pcr_id]'
      select 'pass', :from => 'mi_attempt[qc_loxp_confirmation_id]'
      select 'fail', :from => 'mi_attempt[qc_three_prime_lr_pcr_id]'
      uncheck 'mi_attempt[should_export_to_mart]'
      uncheck 'mi_attempt[is_active]'
      check 'mi_attempt[is_released_from_genotyping]'

      assert_difference 'MiAttempt.count', 1 do
        click_button 'mi_attempt_submit'
        sleep 6
      end

      mi_attempt = MiAttempt.order('id ASC').last

      # Important fields
      assert_equal clone, mi_attempt.clone
      assert_equal MiAttemptStatus.micro_injection_in_progress, mi_attempt.mi_attempt_status
      assert_equal 'ABCD', mi_attempt.colony_name
      assert_equal 'WTSI', mi_attempt.distribution_centre.name
      assert_equal 'ICS', mi_attempt.production_centre.name

      # Transfer details
      assert_equal 'Swiss Webster', mi_attempt.blast_strain.name
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
      assert_equal '129S5', mi_attempt.test_cross_strain.name
      assert_equal 'B6JTyr<c-Brd>', mi_attempt.colony_background_strain.name
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
      create_common_test_objects
      centre = Factory.create :centre, :name => 'Test Centre'
      user = Factory.create :user, :production_centre => centre

      login user.email
      click_link 'Create'

      find('#gene-combo ~ .x-form-arrow-trigger').click
      find('.x-combo-list-item', :text => 'Trafd1').click
      find('#mi_attempt_clone_id ~ .x-form-arrow-trigger').click
      find('div.x-combo-list ~ div.x-combo-list .x-combo-list-item', :text => 'EPD0127_4_E01').click

      assert_difference 'MiAttempt.count', 1 do
        click_button 'mi_attempt_submit'
        sleep 6
      end

      mi_attempt = MiAttempt.order('id ASC').last

      # Important fields
      assert_equal Clone.find_by_clone_name('EPD0127_4_E01'), mi_attempt.clone
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

    should 'save updated_by' do
      create_common_test_objects
      user = Factory.create :user
      login user.email

      click_link 'Create'

      find('#gene-combo ~ .x-form-arrow-trigger').click
      find('.x-combo-list-item', :text => '[All]').click
      find('#mi_attempt_clone_id ~ .x-form-arrow-trigger').click
      find('div.x-combo-list ~ div.x-combo-list .x-combo-list-item').click

      assert_difference 'MiAttempt.count', 1 do
        click_button 'mi_attempt_submit'
        sleep 6
      end

      mi_attempt = MiAttempt.order('id ASC').last

      assert_equal user, mi_attempt.updated_by
    end

  end
end

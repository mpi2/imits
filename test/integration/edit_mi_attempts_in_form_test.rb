# encoding: utf-8

require 'test_helper'

class EditMiAttemptsInFormTest < ActionDispatch::IntegrationTest
  context 'When editing MI Attempt in form' do

    setup do
      create_common_test_objects
      @mi_attempt = Factory.create(:mi_attempt,
        :es_cell => EsCell.find_by_name('EPD0343_1_H06'),
        :mi_date => '2011-06-09',
        :date_chimeras_mated => '2011-06-02',
        :colony_name => 'MAAB',
        :total_blasts_injected => 12,
        :emma_status => 'suitable_sticky',
        :test_cross_strain_name => '129P2'
      )
      login
      visit mi_attempt_path(@mi_attempt)
    end

    should 'show but not allow editing es_cell or gene' do
      assert_match /Myo1c/, page.find('.marker-symbol').text
      assert_match /EPD0343_1_H06/, page.find('.es-cell-name').text
    end

    should 'show default values' do
      assert_equal '129P2', page.find('select[name="mi_attempt[test_cross_strain_name]"] option[selected=selected]').text
      assert_equal 'MAAB', page.find('input[name="mi_attempt[colony_name]"]').value
      assert_equal '09/06/2011', page.find('input[name="mi_attempt[mi_date]"]').value
      assert_equal '02/06/2011', page.find('input[name="mi_attempt[date_chimeras_mated]"]').value
      assert_equal '12', page.find('input[name="mi_attempt[total_blasts_injected]"]').value
      assert_equal 'suitable_sticky', page.find('select[name="mi_attempt[emma_status]"] option[selected=selected]').value
    end

    should 'edit mi successfully, set updated_by and redirect back to show page' do
      fill_in 'mi_attempt[colony_name]', :with => 'ABCD'
      fill_in 'mi_attempt[total_blasts_injected]', :with => 22
      select 'Suitable for EMMA - STICKY', :from => 'mi_attempt[emma_status]'
      select 'C57BL/6N', :from => 'mi_attempt[test_cross_strain_name]'
      select 'pass', :from => 'mi_attempt[qc_southern_blot_result]'
      check 'mi_attempt[report_to_public]'

      assert_difference 'MiAttempt.count', 0 do
        click_button 'mi_attempt_submit'
        sleep 3
      end

      @mi_attempt.reload
      assert_equal 'ABCD', @mi_attempt.colony_name
      assert_equal 22, @mi_attempt.total_blasts_injected
      assert_equal 'suitable_sticky', @mi_attempt.emma_status
      assert_equal 'C57BL/6N', @mi_attempt.test_cross_strain.name
      assert_equal 'pass', @mi_attempt.qc_southern_blot.description
      assert_equal true, @mi_attempt.report_to_public?
      assert_equal default_user.email, @mi_attempt.updated_by.email

      assert_match /\/mi_attempts\/#{@mi_attempt.id}$/, current_url
      assert_equal @mi_attempt.colony_name, page.find('input[name="mi_attempt[colony_name]"]').value
    end

    should 'handle validation errors' do
      assert MiAttempt.find_by_colony_name!('MBSS')
      fill_in 'mi_attempt[colony_name]', :with => 'MBSS'
      assert_difference 'MiAttempt.count', 0 do
        click_button 'mi_attempt_submit'
        sleep 3
      end
      assert_match /\/mi_attempts\/\d+$/, current_url
      assert page.has_css? '.message.alert'
      assert page.has_css? '.field_with_errors'
      assert page.has_css? '.error-message'
    end

    should 'show status change history' do
      # TODO move this to a factory if status stamp tests are more common?
      mi = Factory.create :mi_attempt_genotype_confirmed
      mi.status_stamps.first.update_attributes(:created_at => Time.parse('2011-07-07'))

      mi.status_stamps.create!(
        :mi_attempt_status_id => MiAttemptStatus.micro_injection_aborted,
        :created_at => Time.parse('2011-06-06'))
      mi.status_stamps.create!(
        :mi_attempt_status_id => MiAttemptStatus.genotype_confirmed,
        :created_at => Time.parse('2011-05-05'))
      mi.status_stamps.create!(
        :mi_attempt_status_id => MiAttemptStatus.micro_injection_in_progress,
        :created_at => Time.parse('2011-04-04'))

      mi.mi_plan.status_stamps.first.update_attributes(:created_at => Time.parse('2011-03-03'))
      mi.mi_plan.status_stamps.create!(
        :mi_plan_status_id => MiPlanStatus[:Conflict],
        :created_at => Time.parse('2011-02-02'))
      mi.mi_plan.status_stamps.create!(
        :mi_plan_status_id => MiPlanStatus[:Interest],
        :created_at => Time.parse('2011-01-01'))

      sleep 2

      visit "/mi_attempts/#{mi.id}"

      assert page.has_css? 'li', :text => '01 Jan 2011 Interest'
      assert page.has_css? 'li', :text => '02 Feb 2011 Conflict'
      assert page.has_css? 'li', :text => '03 Mar 2011 Assigned'
      assert page.has_css? 'li', :text => '04 Apr 2011 Micro-injection in progress'
      assert page.has_css? 'li', :text => '05 May 2011 Genotype confirmed'
      assert page.has_css? 'li', :text => '06 Jun 2011 Micro-injection aborted'
      assert page.has_css? 'li', :text => '07 Jul 2011 Genotype confirmed'
    end

  end
end

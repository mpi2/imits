# encoding: utf-8

require 'test_helper'

class EditMiAttemptsInFormTest < ActionDispatch::IntegrationTest
  context 'When editing MI Attempt in form' do

    setup do
      create_common_test_objects
      @mi_attempt = Factory.create(:mi_attempt,
        :clone => Clone.find_by_clone_name('EPD0343_1_H06'),
        :mi_date => '2011-06-09',
        :date_chimeras_mated => '2011-06-02',
        :colony_name => 'MAAB',
        :total_blasts_injected => 12,
        :emma_status => :suitable_sticky,
        :test_cross_strain_id => Strain.find_by_name('129S5').id
      )
      login
      visit mi_attempt_path(@mi_attempt)
    end

    should 'show but not allow editing clone or gene'

    should 'show default values' do
      assert_equal '129S5', page.find('select[name="mi_attempt[test_cross_strain_id]"] option[selected=selected]').text
      assert_equal 'MAAB', page.find('input[name="mi_attempt[colony_name]"]').value
      assert_equal '09/06/2011', page.find('input[name="mi_attempt[mi_date]"]').value
      assert_equal '02/06/2011', page.find('input[name="mi_attempt[date_chimeras_mated]"]').value
      assert_equal '12', page.find('input[name="mi_attempt[total_blasts_injected]"]').value
      assert_equal 'suitable_sticky', page.find('select[name="mi_attempt[emma_status]"] option[selected=selected]').value
    end

    should 'edit mi successfully' do
      fill_in 'mi_attempt[colony_name]', :with => 'ABCD'
      fill_in 'mi_attempt[total_blasts_injected]', :with => 22
      select 'Suitable for EMMA - STICKY', :from => 'mi_attempt[emma_status]'
      select '129S5', :from => 'mi_attempt[test_cross_strain_id]'
      select 'pass', :from => 'mi_attempt[qc_southern_blot_id]'
      check 'mi_attempt[should_export_to_mart]'

      assert_difference 'MiAttempt.count', 0 do
        click_button 'mi_attempt_submit'
        sleep 6
      end

      @mi_attempt.reload
      assert_equal 'ABCD', @mi_attempt.colony_name
      assert_equal 22, @mi_attempt.total_blasts_injected
      assert_equal :suitable_sticky, @mi_attempt.emma_status
      assert_equal '129S5', @mi_attempt.test_cross_strain.name
      assert_equal 'pass', @mi_attempt.qc_southern_blot.description
      assert_equal true, @mi_attempt.should_export_to_mart?
    end

    should 'set updated_by'

    should 'redirect back to show page'

  end
end

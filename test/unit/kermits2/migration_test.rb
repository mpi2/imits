# encoding: utf-8

require 'test_helper'

class Kermits2::MigrationTest < ActiveSupport::TestCase

  context 'Kermits2::Migration' do
    setup do
      Pipeline.destroy_all
      Centre.destroy_all
      assert_equal 0, MiAttempt.count
    end

    should 'work from the script' do
      flunk
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
    end

    context 'migrating an mi attempt' do
      should 'create clone using data from marts if it does not already exist' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029])
        assert_equal 1, MiAttempt.count

        mi_attempt = MiAttempt.first
        clone = mi_attempt.clone

        assert_equal 'EPD0127_4_E01', clone.clone_name
      end

      should 'create 2 mi attempts of the same clone' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029, 11101])
        assert_equal 2, MiAttempt.count
      end

      should 'migrate its centres' do
        Kermits2::Migration.run(:mi_attempt_ids => [11029])
        assert_equal 1, MiAttempt.count
        mi_attempt = MiAttempt.first

        assert_equal 'WTSI', mi_attempt.production_centre.name
        assert_equal 'CNB', mi_attempt.distribution_centre.name
      end

      should 'migrate numeric fields' do
        old_mi_attempts = Old::MiAttempt.find(5268, 3973)
        assert_not_empty old_mi_attempts

        Kermits2::Migration.run(:mi_attempt_ids => [5268, 3973])
        assert_equal 2, MiAttempt.count

        mi_5268, mi_3973 = MiAttempt.find(:all, :order => 'id asc')

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
      end
    end

  end
end

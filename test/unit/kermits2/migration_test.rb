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

      should 'migrate numeric fields from transfer details' do
        old_mi_attempt = Old::MiAttempt.find(5268)
        assert_not_nil old_mi_attempt

        Kermits2::Migration.run(:mi_attempt_ids => [5268])
        assert_equal 1, MiAttempt.count

        mi_attempt = MiAttempt.first
        assert_equal 40, mi_attempt.total_blasts_injected
        assert_equal 80, mi_attempt.total_transferred
        assert_equal nil, mi_attempt.number_surrogates_receiving
      end
    end

  end
end

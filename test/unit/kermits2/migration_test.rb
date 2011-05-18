# encoding: utf-8

require 'test_helper'

class Kermits2::MigrationTest < ActiveSupport::TestCase

  context 'Kermits2::Migration' do
    setup do
      Centre.destroy_all
    end

    should 'work from the script' do
      flunk
    end

    should 'migrate across centres' do
      Kermits2::Migration.run(:mi_attempt_ids => [])

      centre_names = Centre.all.collect(&:name)
      assert_include centre_names, 'ICS'
      assert_include centre_names, 'WTSI'
      assert_include centre_names, 'Monterotondo'
    end

    should 'migrate across pipelines' do
      flunk
    end

    context 'migrating an mi attempt' do
      should 'migrate across the clone using data from marts if it does not already exist' do
        old_mi_attempt = Old::MiAttempt.find(11029)
        assert_not_nil old_mi_attempt

        Kermits2::Migration.run(:mi_attempt_ids => [11029])
        assert_equal 1, MiAttempt.count

        mi_attempt = MiAttempt.first
        clone = mi_attempt.clone

        assert_equal 'EPD0127_4_E01', clone.clone_name
      end

      should 'migrate centres' do
        flunk
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

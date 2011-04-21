# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do
    setup do
      @mi_attempt = Factory.create :mi_attempt
    end

    should have_db_column(:clone_id).with_options(:null => false)
    should belong_to :clone
    should validate_presence_of :clone

    should have_db_column :centre_id
    should belong_to :centre

    should have_db_column :distribution_centre_id
    should belong_to :distribution_centre

    should have_db_column(:mi_attempt_status_id).with_options(:null => false)
    should belong_to :mi_attempt_status

    should validate_presence_of :mi_attempt_status

    should 'set mi_attempt_status to "In progress" by default' do
      assert_equal 'In progress', @mi_attempt.mi_attempt_status.description
    end

    should 'not overwrite status if it is set explicitly' do
      mi_attempt = Factory.build(:mi_attempt, :mi_attempt_status => MiAttemptStatus.good)
      assert_equal 'Good', mi_attempt.mi_attempt_status.description
    end

    should belong_to :blast_strain



    should have_db_column(:is_suitable_for_emma).with_options(:null => false)
    should have_db_column(:is_emma_sticky).with_options(:null => false)

    should 'set is_suitable_for_emma to false by default' do
      assert_equal false, @mi_attempt.is_suitable_for_emma?
    end

    should 'set is_emma_sticky to false by default' do
      assert_equal false, @mi_attempt.is_suitable_for_emma?
    end

    context '#emma_status' do
      should 'be :suitable if is_suitable_for_emma=true and is_emma_sticky=false' do
        @mi_attempt.is_suitable_for_emma = true
        @mi_attempt.is_emma_sticky = false
        assert_equal :suitable, @mi_attempt.emma_status
      end

      should 'be :unsuitable if is_suitable_for_emma=false and is_emma_sticky=false' do
        @mi_attempt.is_suitable_for_emma = false
        @mi_attempt.is_emma_sticky = false
        assert_equal :unsuitable, @mi_attempt.emma_status
      end

      should 'be :suitable_sticky if is_suitable_for_emma=true and is_emma_sticky=true' do
        @mi_attempt.is_suitable_for_emma = true
        @mi_attempt.is_emma_sticky = true
        assert_equal :suitable_sticky, @mi_attempt.emma_status
      end

      should 'be :unsuitable_sticky if is_suitable_for_emma=false and is_emma_sticky=true' do
        @mi_attempt.is_suitable_for_emma = false
        @mi_attempt.is_emma_sticky = true
        assert_equal :unsuitable_sticky, @mi_attempt.emma_status
      end
    end

    context '#emma_status=' do
      should 'work for suitable' do
        @mi_attempt.emma_status = 'suitable'
        @mi_attempt.save!
        @mi_attempt.reload
        assert_equal [true, false], [@mi_attempt.is_suitable_for_emma?, @mi_attempt.is_emma_sticky?]
      end

      should 'work for unsuitable' do
        @mi_attempt.emma_status = 'unsuitable'
        @mi_attempt.save!
        @mi_attempt.reload
        assert_equal [false, false], [@mi_attempt.is_suitable_for_emma?, @mi_attempt.is_emma_sticky?]
      end

      should 'work for :suitable_sticky' do
        @mi_attempt.emma_status = 'suitable_sticky'
        @mi_attempt.save!
        @mi_attempt.reload
        assert_equal [true, true], [@mi_attempt.is_suitable_for_emma?, @mi_attempt.is_emma_sticky?]
      end

      should 'work for :unsuitable_sticky' do
        @mi_attempt.emma_status = 'unsuitable_sticky'
        @mi_attempt.save!
        @mi_attempt.reload
        assert_equal [false, true], [@mi_attempt.is_suitable_for_emma?, @mi_attempt.is_emma_sticky?]
      end

      should 'error for anything else' do
        assert_raise(MiAttempt::EmmaStatusError) do
          @mi_attempt.emma_status = 'invalid'
        end
      end

      should 'set cause #emma_status to return the right value after being saved' do
        @mi_attempt.emma_status = 'unsuitable_sticky'
        @mi_attempt.save!
        @mi_attempt.reload

        assert_equal [false, true], [@mi_attempt.is_suitable_for_emma?, @mi_attempt.is_emma_sticky?]
        assert_equal :unsuitable_sticky, @mi_attempt.emma_status
      end
    end

  end
end

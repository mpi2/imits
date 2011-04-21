# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do
    setup do
      @mi_attempt = Factory.create :mi_attempt,
              :blast_strain => Strain.find_by_name('Balb/C'),
              :colony_background_strain => Strain.find_by_name('129P2/OlaHsd'),
              :test_cross_strain => Strain.find_by_name('129P2/OlaHsd')
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

    should 'have a blast strain' do
      assert_equal Strain, @mi_attempt.blast_strain.class
      assert_equal 'Balb/C', @mi_attempt.blast_strain.name
    end

    should 'have a colony background strain' do
      assert_equal Strain, @mi_attempt.colony_background_strain.class
      assert_equal '129P2/OlaHsd', @mi_attempt.colony_background_strain.name
    end

    should 'have a test cross strain' do
      assert_equal Strain, @mi_attempt.test_cross_strain.class
      assert_equal '129P2/OlaHsd', @mi_attempt.test_cross_strain.name
    end

    should 'not allow adding a strain if it is not of the correct type' do
      strain = Strain.create!(:name => 'Nonexistent Strain')

      assert_raise ActiveRecord::InvalidForeignKey do
        Factory.create(:mi_attempt, :blast_strain_id => strain.id)
      end

      assert_raise ActiveRecord::InvalidForeignKey do
        Factory.create(:mi_attempt, :colony_background_strain_id => strain.id)
      end

      assert_raise ActiveRecord::InvalidForeignKey do
        Factory.create(:mi_attempt, :test_cross_strain_id => strain.id)
      end
    end

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

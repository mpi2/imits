# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create :mi_attempt,
              :blast_strain_id => Strain.find_by_name('Balb/C').id,
              :colony_background_strain_id => Strain.find_by_name('129P2/OlaHsd').id,
              :test_cross_strain_id => Strain.find_by_name('129P2/OlaHsd').id
    end

    should 'have clone' do
      assert_accepts have_db_column(:clone_id).with_options(:null => false), MiAttempt.new
      assert_accepts belong_to(:clone), MiAttempt.new
      assert_accepts validate_presence_of(:clone), MiAttempt.new
    end

    should 'have centres' do
      assert_accepts have_db_column(:production_centre_id).with_options(:null => false), MiAttempt.new
      assert_accepts belong_to(:production_centre), MiAttempt.new

      assert_accepts have_db_column(:distribution_centre_id), MiAttempt.new
      assert_accepts belong_to(:distribution_centre), MiAttempt.new
    end

    context 'distribution_centre' do
      should 'should default to production_centre if not set' do
        mi_attempt = Factory.create :mi_attempt, :production_centre => Centre.find_by_name('WTSI')
        assert_equal 'WTSI', mi_attempt.distribution_centre.name
      end

      should 'not default if already set' do
        mi_attempt = Factory.create :mi_attempt,
                :production_centre => Centre.find_by_name('WTSI'),
                :distribution_centre => Centre.find_by_name('ICS')
        assert_equal 'ICS', mi_attempt.distribution_centre.name
      end
    end

    should 'have status' do
      assert_accepts have_db_column(:mi_attempt_status_id).with_options(:null => false), MiAttempt.new
      assert_accepts belong_to(:mi_attempt_status), MiAttempt.new
    end

    should 'set mi_attempt_status to "In progress" by default' do
      assert_equal 'In progress', default_mi_attempt.mi_attempt_status.description
    end

    should 'not overwrite status if it is set explicitly' do
      mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.good)
      assert_equal 'Good', mi_attempt.mi_attempt_status.description
    end

    should 'not reset status to default if assigning id' do
      local_mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.good)
      local_mi_attempt.mi_attempt_status_id = MiAttemptStatus.good.id
      local_mi_attempt.save!
      local_mi_attempt = MiAttempt.find(local_mi_attempt.id)
      assert_equal 'Good', local_mi_attempt.mi_attempt_status.description
    end

    should 'have mouse allele name related column' do
      assert_accepts have_db_column(:mouse_allele_name_derivative_allele_suffix), default_mi_attempt
    end

    should 'have a blast strain' do
      assert_equal Strain::BlastStrainId, default_mi_attempt.blast_strain.class
      assert_equal 'Balb/C', default_mi_attempt.blast_strain.name
    end

    should 'have a colony background strain' do
      assert_equal Strain, default_mi_attempt.colony_background_strain.class
      assert_equal '129P2/OlaHsd', default_mi_attempt.colony_background_strain.name
    end

    should 'have a test cross strain' do
      assert_equal Strain, default_mi_attempt.test_cross_strain.class
      assert_equal '129P2/OlaHsd', default_mi_attempt.test_cross_strain.name
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

    should 'have emma columns' do
      assert_accepts have_db_column(:is_suitable_for_emma).with_options(:null => false), MiAttempt.new
      assert_accepts have_db_column(:is_emma_sticky).with_options(:null => false), MiAttempt.new
    end

    should 'set is_suitable_for_emma to false by default' do
      assert_equal false, default_mi_attempt.is_suitable_for_emma?
    end

    should 'set is_emma_sticky to false by default' do
      assert_equal false, default_mi_attempt.is_suitable_for_emma?
    end

    context '#emma_status' do
      should 'be :suitable if is_suitable_for_emma=true and is_emma_sticky=false' do
        default_mi_attempt.is_suitable_for_emma = true
        default_mi_attempt.is_emma_sticky = false
        assert_equal :suitable, default_mi_attempt.emma_status
      end

      should 'be :unsuitable if is_suitable_for_emma=false and is_emma_sticky=false' do
        default_mi_attempt.is_suitable_for_emma = false
        default_mi_attempt.is_emma_sticky = false
        assert_equal :unsuitable, default_mi_attempt.emma_status
      end

      should 'be :suitable_sticky if is_suitable_for_emma=true and is_emma_sticky=true' do
        default_mi_attempt.is_suitable_for_emma = true
        default_mi_attempt.is_emma_sticky = true
        assert_equal :suitable_sticky, default_mi_attempt.emma_status
      end

      should 'be :unsuitable_sticky if is_suitable_for_emma=false and is_emma_sticky=true' do
        default_mi_attempt.is_suitable_for_emma = false
        default_mi_attempt.is_emma_sticky = true
        assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
      end
    end

    context '#emma_status=' do
      should 'work for suitable' do
        default_mi_attempt.emma_status = 'suitable'
        default_mi_attempt.save!
        default_mi_attempt.reload
        assert_equal [true, false], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
      end

      should 'work for unsuitable' do
        default_mi_attempt.emma_status = 'unsuitable'
        default_mi_attempt.save!
        default_mi_attempt.reload
        assert_equal [false, false], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
      end

      should 'work for :suitable_sticky' do
        default_mi_attempt.emma_status = 'suitable_sticky'
        default_mi_attempt.save!
        default_mi_attempt.reload
        assert_equal [true, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
      end

      should 'work for :unsuitable_sticky' do
        default_mi_attempt.emma_status = 'unsuitable_sticky'
        default_mi_attempt.save!
        default_mi_attempt.reload
        assert_equal [false, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
      end

      should 'error for anything else' do
        assert_raise(MiAttempt::EmmaStatusError) do
          default_mi_attempt.emma_status = 'invalid'
        end
      end

      should 'set cause #emma_status to return the right value after being saved' do
        default_mi_attempt.emma_status = 'unsuitable_sticky'
        default_mi_attempt.save!
        default_mi_attempt.reload

        assert_equal [false, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
        assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
      end
    end

    context 'QC fields' do
      MiAttempt::QC_FIELDS.each do |qc_field|
        should "include #{qc_field}" do
          assert_accepts belong_to(qc_field), MiAttempt.new
        end
      end
    end

  end
end

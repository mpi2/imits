# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::StatusChangerTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt::StatusChanger' do

    def phenotype_attempt
      @phenotype_attempt ||= Factory.build :phenotype_attempt
    end

    should 'not set a status if any of its required statuses conditions are not met as well' do
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = nil
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Rederivation Started -> ' +
            'Rederivation Complete -> Cre Excision Started -> ' +
            'Cre Excision Complete -> Phenotyping Started -> Phenotyping Complete' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Started', phenotype_attempt.status.name

      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.valid?
      assert_equal 'Rederivation Complete', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Complete', phenotype_attempt.status.name
    end

    should 'not crash when checking for Cre Excision Complete if number_of_cre_matings_successful us nil' do
      phenotype_attempt.rederivation_started = true
      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = nil
      phenotype_attempt.mouse_allele_type = 'b'
      assert_nothing_raised { phenotype_attempt.valid? }
    end

    should 'transition through Phenotype Attempt Registered -> Cre Excision Started -> Cre Excision Complete with mouse_allele_type of "b"' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Cre Excision Started -> Cre Excision Complete with mouse_allele_type of ".1"' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Started', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.mouse_allele_type = '.1'
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition to Aborted if is_active is set, regardless of other statuses' do
      phenotype_attempt.is_active = false

      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.rederivation_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Aborted', phenotype_attempt.status.name
    end

    should 'transition to Cre Excision Complete if mouse_allele_type is set to "b"' do
      phenotype_attempt.mouse_allele_type = 'b'
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition to Cre Excision Complete if mouse_allele_type is set to ".1"' do
      phenotype_attempt.mouse_allele_type = '.1'
      phenotype_attempt.deleter_strain = DeleterStrain.first
      phenotype_attempt.number_of_cre_matings_successful = 2
      phenotype_attempt.colony_background_strain = Strain.first
      phenotype_attempt.valid?
      assert_equal 'Cre Excision Complete', phenotype_attempt.status.name
    end

    should 'transition through Phenotype Attempt Registered -> Phenotyping Started -> Phenotyping Complete by setting cre_excision_required to false' do
      phenotype_attempt.valid?
      assert_equal 'Phenotype Attempt Registered', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_started = true
      phenotype_attempt.cre_excision_required = false
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Started', phenotype_attempt.status.name

      phenotype_attempt.phenotyping_complete = true
      phenotype_attempt.valid?
      assert_equal 'Phenotyping Complete', phenotype_attempt.status.name
    end

    context 'status stamps' do
      should 'be created if conditions for a status are met' do
        pa = Factory.create :phenotype_attempt
        assert_equal 1, pa.status_stamps.count

        pa.update_attributes!(:rederivation_started => true, :rederivation_complete => true)
        assert_equal 3, pa.status_stamps.count
        assert_equal 'rec', pa.status_stamps.last.code
      end

      should 'be deleted if conditions for a status are not met' do
        mi = Factory.create :phenotype_attempt
        mi.update_attributes!(:is_active => false)
        assert_equal 'abt', mi.status_stamps.last.code
        assert_equal 2, mi.status_stamps.count

        mi.update_attributes!(:is_active => true)
        assert_equal 1, mi.status_stamps.count
        assert_equal 'par', mi.status_stamps.last.code
      end

      should_eventually 'have return order defined by StatusManager' do
        p = Factory.create :phenotype_attempt, :rederivation_started => true,
                :rederivation_complete => true, :deleter_strain => DeleterStrain.first
        replace_status_stamps(p,
          'res' => '2011-01-01',
          'rec' => '2011-01-02',
          'par' => '2011-01-03'
        )
        stamp_codes = p.status_stamps.all.map(&:code)
        assert_equal ['par', 'res', 'rec'], stamp_codes[0..2]
      end
    end

  end
end

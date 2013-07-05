# encoding: utf-8

require 'test_helper'

class Public::PhenotypeAttemptTest < ActiveSupport::TestCase
  context 'Public::PhenotypeAttempt' do

    def default_phenotype_attempt
      @default_phenotype_attempt ||= Factory.create(:phenotype_attempt).to_public
    end

    context '#mi_attempt_colony_name' do
      should 'AccessAssociationByAttribute' do
        mi = Factory.create :mi_attempt2, :colony_name => 'ABCD123'
        default_phenotype_attempt.mi_attempt_colony_name = 'ABCD123'
        assert_equal mi, default_phenotype_attempt.mi_attempt
      end

      should 'validate presence' do
        assert_should validate_presence_of :mi_attempt_colony_name
      end

      should 'not be updateable' do
        mi = Factory.create :mi_attempt2
        default_phenotype_attempt.mi_attempt_colony_name = mi.colony_name
        default_phenotype_attempt.valid?
        assert_match(/cannot be changed/, default_phenotype_attempt.errors[:mi_attempt_colony_name].first)
      end

      should 'be able to be set on create' do
        mi = Factory.create :mi_attempt2_status_gtc
        phenotype_attempt = Factory.create(:public_phenotype_attempt,
        :mi_attempt_colony_name => mi.colony_name)
        phenotype_attempt.valid?
        assert phenotype_attempt.errors[:mi_attempt_colony_name].blank?
      end
    end

    context '#mi_plan' do
      setup do
        @allele = Factory.create(:allele, :gene => cbx1)
        @mi = Factory.create(:mi_attempt2_status_gtc,
        :es_cell => Factory.create(:es_cell, :allele => @allele),
        :mi_plan => TestDummy.mi_plan('BaSH', 'ICS', 'Cbx1'))
      end

      should 'not raise error when being set by before filter if no mi_attempt is found' do
        pt = Public::PhenotypeAttempt.new
        assert_false pt.valid?
      end

      should 'be set to correct MiPlan if neither consortium_name nor production_centre_name are provided' do
        pt = Factory.build(:public_phenotype_attempt, :mi_attempt_colony_name => @mi.colony_name)
        pt.save!
        assert_equal @mi.mi_plan, pt.mi_plan
      end

      should 'set MiPlan to Assigned status if not assigned already' do
        plan = TestDummy.mi_plan(@mi.mi_plan.marker_symbol,
        'JAX', @mi.mi_plan.production_centre.name)
        plan.phenotype_only = true
        assert_equal 'Inspect - GLT Mouse', plan.status.name

        pt = Factory.build(:public_phenotype_attempt,
        :mi_plan => plan,
        :mi_attempt_colony_name => @mi.colony_name)
        pt.save!
        plan.reload
        assert_equal plan, pt.mi_plan
        assert_equal 'Assigned', plan.status.name
      end
    end

    should 'limit the public mass-assignment API' do
      expected = [
        'colony_name',
        'consortium_name',
        'production_centre_name',
        'distribution_centres_attributes',
        'mi_attempt_colony_name',
        'is_active',
        'rederivation_started',
        'rederivation_complete',
        'number_of_cre_matings_successful',
        'phenotyping_started',
        'phenotyping_complete',
        'mouse_allele_type',
        'deleter_strain_name',
        'colony_background_strain_name',
        'cre_excision_required',
        'mi_plan_id',
        'tat_cre',
        'status_stamps_attributes'
      ]
      got = (Public::PhenotypeAttempt.accessible_attributes.to_a - ['audit_comment'])
      assert_equal expected.sort, got.sort
    end

    should 'have defined attributes in JSON output' do
      expected = [
        'id',
        'colony_name',
        'status_name',
        'status_dates',
        'consortium_name',
        'production_centre_name',
        'distribution_centres_attributes',
        'distribution_centres_formatted_display',
        'mi_attempt_colony_name',
        'is_active',
        'marker_symbol',
        'rederivation_started',
        'rederivation_complete',
        'number_of_cre_matings_successful',
        'phenotyping_started',
        'phenotyping_complete',
        'mouse_allele_type',
        'deleter_strain_name',
        'colony_background_strain_name',
        'cre_excision_required',
        'mi_plan_id',
        'tat_cre',
        'mouse_allele_symbol',
        'mouse_allele_symbol_superscript',
        'allele_symbol'
      ]
      got = default_phenotype_attempt.as_json.keys
      assert_equal expected.sort, got.sort
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { default_phenotype_attempt.as_json(nil) }
      end
    end

    context '#status_name' do
      should 'be the status name' do
        default_phenotype_attempt.deleter_strain = DeleterStrain.first
        default_phenotype_attempt.valid?
        assert_equal 'Cre Excision Started', default_phenotype_attempt.status.name
        assert_equal 'Cre Excision Started', default_phenotype_attempt.status_name
      end
    end

    context '::translate_public_param' do
      should 'translate marker_symbol for search' do
        assert_equal 'mi_plan_gene_marker_symbol_eq',
        Public::PhenotypeAttempt.translate_public_param('marker_symbol_eq')
      end

      should 'translate consortium_name for search' do
        assert_equal 'mi_plan_consortium_name_in',
        Public::PhenotypeAttempt.translate_public_param('consortium_name_in')
      end

      should 'translate production_centre_name for search' do
        assert_equal 'mi_plan_production_centre_in',
        Public::PhenotypeAttempt.translate_public_param('production_centre_in')
      end

      should 'leave other params untouched' do
        assert_equal 'phenotyping_started_eq',
        Public::PhenotypeAttempt.translate_public_param('phenotyping_started_eq')
        assert_equal 'deleter_strain_name asc',
        Public::PhenotypeAttempt.translate_public_param('deleter_strain_name asc')
      end
    end

    context '::public_search' do
      should 'not need to pass "sorts" parameter' do
        assert Public::PhenotypeAttempt.public_search(:consortium_name_eq => default_phenotype_attempt.mi_plan.consortium.name, :sorts => nil).result
      end

      should 'translate searching predicates' do
        result = Public::PhenotypeAttempt.public_search(:marker_symbol_eq => default_phenotype_attempt.gene.marker_symbol).result
        assert_equal [default_phenotype_attempt], result
      end
    end

    context '#distribution_centres_attributes' do
      should 'be output correctly' do
        pt = Factory.create(:phenotype_attempt_status_pdc)

        Factory.create(:phenotype_attempt_distribution_centre,
        :start_date => '2012-01-02', :phenotype_attempt => pt)
        Factory.create(:phenotype_attempt_distribution_centre,
        :end_date => '2012-02-02', :phenotype_attempt => pt)
        ds = pt.distribution_centres
        expected = pt.distribution_centres.all.map(&:as_json)

        pt = pt.reload.to_public
        assert_equal expected, pt.distribution_centres_attributes
      end
    end

    context '#status_dates' do

      setup do
        @phenotype_attempt = Factory.create(:public_phenotype_attempt)
        @phenotype_attempt.save!

        @phenotype_attempt.deleter_strain = DeleterStrain.first
        @phenotype_attempt.save!
      end

      should 'show status stamps and their dates' do

        now = Time.now.strftime("%Y-%m-%d")

        status_dates = {
          "Cre Excision Started"=>"#{now}",
          "Phenotype Attempt Registered"=>"#{now}"
        }

        assert_equal status_dates, @phenotype_attempt.status_dates

      end
    end

    context '#colony_name' do

      should 'not allow colony_name to be update if phenotyping has started and phenotype record already exists' do
        @phenotype_attempt = Factory.build(:public_phenotype_attempt, :phenotyping_started => true, :number_of_cre_matings_successful => 2, :deleter_strain_id => 1, :colony_background_strain_id => 1, :mouse_allele_type => 'b')
        assert @phenotype_attempt.valid?
        assert_equal @phenotype_attempt.status.code, 'pds'
        @phenotype_attempt.save
        @phenotype_attempt.colony_name = 'this should NOT be valid'
        assert_false @phenotype_attempt.valid?
      end

      should 'allow colony_name to be update if phenotyping has started and phenotype record does not exist' do
        @phenotype_attempt = Factory.build(:public_phenotype_attempt, :phenotyping_started => true, :number_of_cre_matings_successful => 2, :deleter_strain_id => 1, :colony_background_strain_id => 1, :mouse_allele_type => 'b')
        assert @phenotype_attempt.valid?
        assert_equal @phenotype_attempt.status.code, 'pds'
        @phenotype_attempt.colony_name = 'this should be valid'
        assert @phenotype_attempt.valid?
        assert @phenotype_attempt.save!
      end

      should 'allow colony_name update if phenotyping has NOT started' do
        @phenotype_attempt = Factory.build(:public_phenotype_attempt)
        assert @phenotype_attempt.valid?
        assert_not_equal @phenotype_attempt.status.code, 'pds'
        @phenotype_attempt.colony_name = 'this should be valid'
        assert @phenotype_attempt.valid?
        assert @phenotype_attempt.save!
      end
    end


  end
end

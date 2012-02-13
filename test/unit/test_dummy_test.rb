require 'test_helper'

class TestDummyTest < ActiveSupport::TestCase
  context 'TestDummy' do

    context '::create' do
      should 'set up associations' do
        Factory.create :gene_cbx1
        expected = [
          'Assigned',
          'DTCC',
          'UCD'
        ]
        plan = TestDummy.create(:mi_plan, *expected)
        got = [
          plan.status.name,
          plan.consortium.name,
          plan.production_centre.name
        ]
        assert_equal expected, got
      end

      should 'find associations that do not have a name attribute' do
        Factory.create :gene_cbx1
        expected = [
          'Cbx1'
        ]
        plan = TestDummy.create(:mi_plan, *expected)
        got = [
          plan.gene.marker_symbol
        ]
        assert_equal expected, got
      end

      should 'work for any factory' do
        plan = TestDummy.create(:mi_plan)
        assert_kind_of MiPlan, plan

        pt = TestDummy.create(:phenotype_attempt)
        assert_kind_of PhenotypeAttempt, pt
      end

      should 'raise error if a value could not be found' do
        assert_raise_kind_of(TestDummy::Error) do
          TestDummy.create(:mi_plan, 'NonexistentGene')
        end
      end

      should 'should create the object in the database' do
        plan = TestDummy.create(:mi_plan, 'BaSH', 'WTSI')
        assert plan.id
      end
    end

    context '::mi_plan' do
      should 'be same as create(:mi_plan)' do
        expected = ['BaSH', 'WTSI']
        plan = TestDummy.mi_plan(*expected)
        assert_equal expected, [plan.consortium.name, plan.production_centre.name]
      end
    end

  end
end

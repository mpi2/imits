require 'test_helper'

class ApplicationModel::BelongsToMiPlanTest < ActiveSupport::TestCase
  context 'ApplicationModel::BelongsToMiPlan' do

    setup do
      @object = stub(:gene => cbx1)
      @object.extend ApplicationModel::BelongsToMiPlan
    end

    context '#try_to_find_production_centre_name' do
      should 'return instance variable value regardless of mi_plan or mi_attempt existence' do
        @object.stubs(
          :mi_attempt => stub('mi_attempt', :production_centre => Centre.find_by_name!('WTSI')),
          :mi_plan => stub('plan', :production_centre => Centre.find_by_name!('UCD'))
        )
        @object.instance_variable_set(:@production_centre_name, 'ICS')
        assert_equal 'ICS', @object.try_to_find_production_centre_name
      end

      context 'if not assigned yet' do
        should 'read from mi_plan when it is set and has valid production centre even if an mi_attempt is set' do
          @object.stubs(
            :mi_attempt => stub('mi_attempt', :production_centre => Centre.find_by_name!('WTSI')),
            :mi_plan => stub('plan', :production_centre => Centre.find_by_name!('ICS'))
          )
          assert_equal 'ICS', @object.try_to_find_production_centre_name
        end

        should 'read from mi_attempt if it is set and no mi_plan is set' do
          @object.stubs(
            :mi_attempt => stub('mi_attempt', :production_centre => Centre.find_by_name!('WTSI')),
            :mi_plan => nil
          )
          assert_equal 'WTSI', @object.try_to_find_production_centre_name
        end

        should 'read from mi_attempt if it is set and mi_plan has no production centre' do
          @object.stubs(
            :mi_attempt => stub('mi_attempt', :production_centre => Centre.find_by_name!('WTSI')),
            :mi_plan => stub('plan', :production_centre => nil)
          )
          assert_equal 'WTSI', @object.try_to_find_production_centre_name
        end

        should 'return nil if mi_plan without production centre is set and no mi_attempt is present' do
          @object.stubs(:mi_plan => stub('plan', :production_centre => nil))
          assert_equal nil, @object.try_to_find_production_centre_name
        end

        should 'be nil if no source found' do
          assert_equal nil, @object.try_to_find_production_centre_name
        end
      end
    end

    context '#try_to_find_consortium_name' do
      should 'return what has been explicitly assigned regardless of mi_plan or mi_attempt existence' do
        @object.stubs(
          :mi_attempt => stub('mi_attempt', :consortium => Consortium.find_by_name!('BaSH')),
          :mi_plan => stub('plan', :consortium => Consortium.find_by_name!('DTCC'))
        )
        @object.instance_variable_set(:@consortium_name, 'EUCOMM-EUMODIC')
        assert_equal 'EUCOMM-EUMODIC', @object.try_to_find_consortium_name
      end

      context 'if not assigned yet' do
        should 'read from mi_plan when it is set even if an mi_attempt is set' do
          @object.stubs(
            :mi_attempt => stub('mi_attempt', :consortium => Consortium.find_by_name!('BaSH')),
            :mi_plan => stub('plan', :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'))
          )
          assert_equal 'EUCOMM-EUMODIC', @object.try_to_find_consortium_name
        end

        should 'read from mi_attempt if it is set and no mi_plan is set' do
          @object.stubs(
            :mi_attempt => stub('mi_attempt', :consortium => Consortium.find_by_name!('BaSH')),
            :mi_plan => nil
          )
          assert_equal 'BaSH', @object.try_to_find_consortium_name
        end

        should 'be nil if no source found' do
          @object.stubs(:mi_plan => nil)
          assert_equal nil, @object.try_to_find_consortium_name
        end
      end
    end

    context '#try_to_find_plan' do
      should 'return already set mi_plan if the consortium and production centre are the same as the ones that are found using try_to_find_* methods and gene is the same' do
        plan = stub('plan',
          :production_centre => Centre.find_by_name!('WTSI'),
          :consortium => Consortium.find_by_name!('BaSH'),
          :gene => cbx1)
        @object.stubs(:try_to_find_consortium_name => 'BaSH',
          :try_to_find_production_centre_name => 'WTSI',
          :mi_plan => plan)

        assert_equal plan, @object.try_to_find_plan
      end

      should 'find and return MiPlan with consortium and production centre returned by try_to_find_* methods if they are both present' do
        @object.stubs(:try_to_find_consortium_name => 'BaSH',
          :try_to_find_production_centre_name => 'WTSI')

        plan = TestDummy.mi_plan('BaSH', 'WTSI', 'Cbx1')

        assert_equal plan, @object.try_to_find_plan
      end

      should 'return nil if either of try_to_find_* methods return nil'

      should 'return nil if MiPlan identified by try_to_find_* methods cannot be found'
    end

  end
end

require 'test_helper'
require 'ostruct'

class ApplicationModel::BelongsToMiPlanTest < ActiveSupport::TestCase
  context 'ApplicationModel::BelongsToMiPlan' do

    setup do
      @object = OpenStruct.new
      @object.extend ApplicationModel::BelongsToMiPlan
    end

    context '#try_to_find_production_centre_name' do
      should 'return instance variable value regardless of mi_plan or mi_attempt existence' do
        @object.mi_attempt = OpenStruct.new(:production_centre => Centre.find_by_name!('WTSI'))
        @object.mi_plan = OpenStruct.new(:production_centre => Centre.find_by_name!('UCD'))
        @object.instance_variable_set(:@production_centre_name, 'ICS')
        assert_equal 'ICS', @object.try_to_find_production_centre_name
      end

      context 'if not assigned yet' do
        should 'read from mi_plan when it is set and has valid production centre even if an mi_attempt is set' do
          @object.mi_attempt = OpenStruct.new(:production_centre => Centre.find_by_name!('WTSI'))
          @object.mi_plan = OpenStruct.new(:production_centre => Centre.find_by_name!('ICS'))
          assert_equal 'ICS', @object.try_to_find_production_centre_name
        end

        should 'read from mi_attempt if it is set and no mi_plan is set' do
          @object.mi_attempt = OpenStruct.new(:production_centre => Centre.find_by_name!('WTSI'))
          @object.mi_plan = nil
          assert_equal 'WTSI', @object.try_to_find_production_centre_name
        end

        should 'read from mi_attempt if it is set and mi_plan has no production centre' do
          @object.mi_attempt = OpenStruct.new(:production_centre => Centre.find_by_name!('WTSI'))
          @object.mi_plan = OpenStruct.new(:production_centre => nil)
          assert_equal 'WTSI', @object.try_to_find_production_centre_name
        end

        should 'return nil if mi_plan without production centre is set and no mi_attempt is present' do
          @object.mi_plan = OpenStruct.new(:production_centre => nil)
          assert_equal nil, @object.try_to_find_production_centre_name
        end

        should 'be nil if no source found' do
          assert_equal nil, @object.try_to_find_production_centre_name
        end
      end
    end

    context '#try_to_find_consortium_name' do
      should 'return what has been explicitly assigned regardless of mi_plan or mi_attempt existence' do
        @object.mi_attempt = OpenStruct.new(:consortium => Consortium.find_by_name!('BaSH'))
        @object.mi_plan = OpenStruct.new(:consortium => Consortium.find_by_name!('DTCC'))
        @object.consortium_name = 'EUCOMM-EUMODIC'
        assert_equal 'EUCOMM-EUMODIC', @object.try_to_find_consortium_name
      end

      context 'if not assigned yet' do
        should 'read from mi_plan when it is set even if an mi_attempt is set' do
          @object.mi_attempt = OpenStruct.new(:consortium => Consortium.find_by_name!('BaSH'))
          @object.mi_plan = OpenStruct.new(:consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'))
          assert_equal 'EUCOMM-EUMODIC', @object.try_to_find_consortium_name
        end

        should 'read from mi_attempt if it is set and no mi_plan is set' do
          @object.mi_attempt = OpenStruct.new(:consortium => Consortium.find_by_name!('BaSH'))
          @object.mi_plan = nil
          assert_equal 'BaSH', @object.try_to_find_consortium_name
        end

        should 'be nil if no source found' do
          assert_equal nil, @object.try_to_find_consortium_name
        end
      end
    end

  end
end

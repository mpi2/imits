# encoding: utf-8

require 'test_helper'

class MiAttemptsHelperTest < ActionView::TestCase

  context 'InnerGrid' do

    setup do
      @mi_attempt = emi_attempt('EPD0127_4_E01__1')
    end

    context '::emma_status_column_options' do
      setup do
        @options = MiAttemptsHelper::InnerGrid.emma_status_column_options
      end

      should 'generate working getter' do
        @mi_attempt.emma_status = :suitable
        assert_equal 'Suitable for EMMA', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :unsuitable
        assert_equal 'Unsuitable for EMMA', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :suitable_sticky
        assert_equal 'Suitable for EMMA - STICKY', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :unsuitable_sticky
        assert_equal 'Unsuitable for EMMA - STICKY', @options[:getter].call(@mi_attempt)
      end

      should 'generate working setter' do
        @options[:setter].call(@mi_attempt, 'Unsuitable for EMMA')
        assert_equal :unsuitable, @mi_attempt.emma_status

        @options[:setter].call(@mi_attempt, 'Suitable for EMMA')
        assert_equal :suitable, @mi_attempt.emma_status

        @options[:setter].call(@mi_attempt, 'Suitable for EMMA - STICKY')
        assert_equal :suitable_sticky, @mi_attempt.emma_status

        @options[:setter].call(@mi_attempt, 'Unsuitable for EMMA - STICKY')
        assert_equal :unsuitable_sticky, @mi_attempt.emma_status
      end

      should 'have all values in editor store' do
        assert_equal 4, @options[:editor][:store].size
      end
    end

    context 'distribution_centre_name' do
      setup do
        @options = MiAttemptsHelper::InnerGrid.distribution_centre_name_column_options
      end

      should 'have working setter' do
        assert_equal 'ICS', @mi_attempt.distribution_centre_name
        @options[:setter].call(@mi_attempt, 'WTSI')
        assert_equal 'WTSI', @mi_attempt.distribution_centre_name
      end

      should 'allow selection from all centres' do
        assert_equal Centre.count, @options[:editor][:store].size
      end
    end
  end

end

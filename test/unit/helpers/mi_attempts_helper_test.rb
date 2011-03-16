# encoding: utf-8

require 'test_helper'

class MiAttemptsHelperTest < ActionView::TestCase

  context 'OuterGrid' do
    should 'pass current_username to InnerGrid' do
      outer_grid = MiAttemptsHelper::OuterGrid.new(:current_username => 'zz99')
      inner_grid_config = outer_grid.config[:items].find {|i| i[:name] == :micro_injection_attempts}
      assert_equal 'zz99', inner_grid_config[:current_username]
    end
  end

  context 'InnerGrid' do

    setup do
      @mi_attempt = emi_attempt('EPD0127_4_E01__1')
      @inner_grid = MiAttemptsHelper::InnerGrid.new(:current_username => 'zz99')
    end

    context 'emma_status column options' do
      setup do
        @options = @inner_grid.config[:columns].find {|i| i[:name] == :emma_status}
      end

      should 'have working getter' do
        @mi_attempt.emma_status = :suitable
        assert_equal 'Suitable for EMMA', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :unsuitable
        assert_equal 'Unsuitable for EMMA', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :suitable_sticky
        assert_equal 'Suitable for EMMA - STICKY', @options[:getter].call(@mi_attempt)

        @mi_attempt.emma_status = :unsuitable_sticky
        assert_equal 'Unsuitable for EMMA - STICKY', @options[:getter].call(@mi_attempt)
      end

      should 'have working setter' do
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

    context 'distribution_centre_name column options' do
      setup do
        @options = @inner_grid.config[:columns].find {|i| i[:name] == :distribution_centre_name}
      end

      should 'have working setter' do
        assert_equal 'ICS', @mi_attempt.distribution_centre_name
        @options[:setter].call(@mi_attempt, 'WTSI')
        assert_equal 'WTSI', @mi_attempt.distribution_centre_name
        assert_equal 'zz99', @mi_attempt.emi_event.edited_by
      end

      should 'allow selection from all centres' do
        assert_equal Centre.count, @options[:editor][:store].size
      end
    end

    context 'strong_default_attrs' do
      should 'have edited_by set to current_username' do
        assert_equal 'zz99', @inner_grid.config[:strong_default_attrs].symbolize_keys[:edited_by]
      end
    end
  end

end

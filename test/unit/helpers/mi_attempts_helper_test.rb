# encoding: utf-8

require 'test_helper'

class MiAttemptsHelperTest < ActionView::TestCase

  context 'MiAttemptsWidget' do
    should 'pass current_username to MiAttemptsGrid' do
      widget = MiAttemptsHelper::MiAttemptsWidget.new(:current_username => 'zz99')
      grid_config = widget.config[:items].find {|i| i[:name] == :micro_injection_attempts}
      assert_equal 'zz99', grid_config[:current_username]
    end
  end

  context 'MiAttemptsGrid' do

    setup do
      @mi_attempt = Factory.create :mi_attempt
      3.times { Factory.create :centre }
      @grid = MiAttemptsHelper::MiAttemptsGrid.new(:current_username => 'zz99')
    end

    context 'distribution_centre_name column options' do
      setup do
        @options = @grid.config[:columns].find {|i| i[:name] == 'distribution_centre_name'}
      end

      should 'have working setter' do
        assert_equal 'ICS', @mi_attempt.distribution_centre_name
        @options[:setter].call(@mi_attempt, 'WTSI')
        assert_equal 'WTSI', @mi_attempt.distribution_centre_name
        assert_equal 'zz99', @mi_attempt.emi_event.edited_by
      end

      should 'allow selection from all centres' do
        assert_not_equal 0, Centre.count
        assert_equal Centre.count, @options[:editor][:store].size
      end
    end

    context 'strong_default_attrs' do
      should 'have edited_by set to current_username' do
        assert_equal 'zz99', @grid.config[:strong_default_attrs].symbolize_keys[:edited_by]
      end
    end
  end

end

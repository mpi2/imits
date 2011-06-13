# encoding: utf-8

require 'test_helper'

class MiAttemptsHelperTest < ActionView::TestCase

  context 'MiAttemptsWidget' do
    should 'pass current_user_id to MiAttemptsGrid' do
      user = Factory.create :user
      widget = MiAttemptsHelper::MiAttemptsWidget.new(:current_user_id => user.id)
      grid_config = widget.config[:items].find {|i| i[:name] == :micro_injection_attempts}
      assert_equal user.id, grid_config[:current_user_id]
    end
  end

  context 'MiAttemptsGrid' do

    setup do
      @user1, @user2 = Factory.create(:user), Factory.create(:user)
      @mi_attempt = Factory.create :mi_attempt, :updated_by => @user1
      @grid = MiAttemptsHelper::MiAttemptsGrid.new(:current_user_id => @user2.id)
    end

    context 'strong_default_attrs' do
      should 'have updated_by_id set to current_user_id' do
        assert_equal @user2.id, @grid.config[:strong_default_attrs].symbolize_keys[:updated_by_id]
      end
    end
  end

end

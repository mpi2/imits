# encoding: utf-8

require 'test_helper'

class Public::MiAttemptTest < ActiveSupport::TestCase
  context 'Public::MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create(:mi_attempt).to_public
    end

    should 'limit the public mass-assignment API' do
      expected = [
      ]
      got = (Public::MiPlan.accessible_attributes.to_a - ['audit_comment'])
      assert_equal expected.sort, got.sort
    end

    should 'have defined attributes in JSON output' do
      expected = [
        'id',
      ]
      got = default_mi_plan.as_json.keys
      assert_equal expected.sort, got.sort
    end

    context '#as_json' do
      should 'take nil as param' do
        assert_nothing_raised { default_mi_plan.as_json(nil) }
      end
    end

  end
end

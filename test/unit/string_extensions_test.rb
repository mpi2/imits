# encoding: utf-8

require 'test_helper'

class StringExtensionsTest < ActiveSupport::TestCase
  context 'String' do
    should '#to_json_variable' do
      assert_equal ActiveSupport::JSON::Variable.new('foo'), 'foo'.to_json_variable
    end
  end
end

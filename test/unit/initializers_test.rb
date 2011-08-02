# encoding: utf-8

require 'test_helper'

class InitializersTest < ActiveSupport::TestCase
  context 'Initializer' do

    context 'to_json_config' do

      should 'set include_root_in_json to false' do
        obj = Test::Person.new
        obj.name = 'Fred'
        assert_equal({'name' => 'Fred'}, obj.as_json)
      end
    end

  end
end

# encoding: utf-8

require 'test_helper'

class InitializersTest < ActiveSupport::TestCase
  context 'Initializer' do

    context 'to_json_config' do

      class Person < ActiveRecord::Base
        self.establish_connection({:adapter => 'sqlite3', :database => ':memory:', :verbosity => false})

        self.connection.create_table 'people', :force => true do |t|
          t.text 'name'
        end
      end

      should 'set include_root_in_json to false' do
        obj = Person.new
        y obj.class.name
        obj.name = 'Fred'
        assert_equal({'name' => 'Fred'}, obj.as_json)
      end
    end

  end
end

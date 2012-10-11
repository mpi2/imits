require 'test_helper'

class ApplicationModel::HasStatusesTest < ActiveSupport::TestCase
  context 'ApplicationModel::HasStatuses' do

    context '#status_class' do
      should 'work' do
        assert_equal Test::Person::Status, Test::Person.status_class
        assert_equal Test::Person::Status, Test::Person.new.status_class
      end
    end

    context '#has_status?' do
      setup do
        @person = Test::Person.create!(:name => 'Bob')
        @person.status_stamps.create!(:status => Test::Person::Status::ALIVE)
        @person.status_stamps.create!(:status => Test::Person::Status::DEAD)
      end

      should 'be true if status stamps include given status' do
        assert_equal true, @person.has_status?(Test::Person::Status::ALIVE)
      end

      should 'be false if status stamps do not include given status' do
        assert_equal false, @person.has_status?(Test::Person::Status::BURIED)
      end

      should 'work with status codes' do
        assert_equal true, @person.has_status?(:alive)
        assert_equal false, @person.has_status?(:buried)
      end

      should 'work with status names' do
        assert_equal true, @person.has_status?('Alive')
        assert_equal false, @person.has_status?('Buried')
      end
    end

  end
end

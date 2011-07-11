# encoding: utf-8

require 'test_helper'

class CentreTest < ActiveSupport::TestCase
  context 'Centre' do
    context '(misc. tests)' do
      setup do
        Factory.create :centre
      end

      should have_db_column(:name).of_type(:string).with_options(:null => false, :limit => 100)
      should have_db_index(:name).unique(true)
      should validate_presence_of :name
      should validate_uniqueness_of :name
    end

    should 'order by name by default' do
      Factory.create :centre, :name => 'ZZ2'
      Factory.create :centre, :name => 'ZZ1'
      Factory.create :centre, :name => 'AA9'
      Factory.create :centre, :name => 'AA1'

      assert_equal %w{AA1 AA9 ICS WTSI ZZ1 ZZ2}, Centre.all.map(&:name)
    end
  end
end

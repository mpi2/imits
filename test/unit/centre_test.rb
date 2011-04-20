require 'test_helper'

class CentreTest < ActiveSupport::TestCase
  context 'Centre' do
    setup do
      Factory.create :centre
    end

    should have_db_column(:name).of_type(:text).with_options(:null => false)
    should validate_presence_of :name
    should validate_uniqueness_of :name
  end
end

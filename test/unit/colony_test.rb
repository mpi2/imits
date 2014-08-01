require 'test_helper'

class ColonyTest < ActiveSupport::TestCase
  context 'Colony' do
    should validate_presence_of :name

    should belong_to :mi_attempt
  end
end

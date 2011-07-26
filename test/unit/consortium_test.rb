require 'test_helper'

class ConsortiumTest < ActiveSupport::TestCase
  context 'Consortium' do
    context '(misc. tests)' do
      should validate_presence_of :name
      should validate_uniqueness_of :name
      should have_many :mi_attempts
    end
  end
end

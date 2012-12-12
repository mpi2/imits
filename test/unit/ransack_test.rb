# encoding: utf-8

require 'test_helper'

class RansackTest < ActiveSupport::TestCase
  context 'Ransack predicate' do

    context 'ci_in' do
      should 'work' do
        a = Factory.create(:mi_attempt2, :colony_name => 'MAAB')
        b = Factory.create(:mi_attempt2, :colony_name => 'MAAN')

        assert_equal [a, b].sort,
                MiAttempt.search(:colony_name_ci_in => ['maab', 'maan']).result.sort
      end
    end

  end
end

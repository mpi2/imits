# encoding: utf-8

require 'test_helper'

class MutagenesisFactorTest < ActiveSupport::TestCase
  context 'MutagenesisFactor' do

    should have_many(:crisprs)
    should have_one(:mi_attempt)
    should belong_to(:vector)

    context "Crispr's" do
      should "be invalid if no crisprs are provided" do
        mf = MutagenesisFactor.new
        assert_false mf.valid?
        assert_true mf.errors.messages[:crisprs].include?("missing. Please input at least one crispr")
      end

      should "be valid if a crisprs is provided" do
        mf = MutagenesisFactor.new({:crisprs_attributes => [{:sequence => (1..23).map{['A','C','G','T'][rand(4)]}.join, :chr => [("1".."19").to_a, ['X', 'Y', 'MT']].flatten[rand(22)], :start => 1, :end => 2}]})
        assert_true mf.valid?
      end
    end
  end
end

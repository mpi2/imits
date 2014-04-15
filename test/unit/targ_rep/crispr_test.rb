# encoding: utf-8

require 'test_helper'

class TargRep::CrisprTest < ActiveSupport::TestCase
  context 'TargRep::Crispr' do
    setup do
      mf = MutagenesisFactor.new({:crisprs_attributes => [{:sequence => (1..23).map{['A','C','G','T'][rand(4)]}.join, :chr => [("1".."19").to_a, ['X', 'Y', 'MT']].flatten[rand(22)], :start => 1, :end => 2}]})
      mf.save
    end

    should belong_to(:mutagenesis_factor)

    should validate_presence_of :mutagenesis_factor
    should validate_uniqueness_of(:sequence).scoped_to(:mutagenesis_factor_id)
    should ensure_length_of(:sequence).is_equal_to(23)
    should allow_value('ACGTACGTACGTACGTACGTACG', 'acgtacgtacgtacgtacgtacg').for(:sequence)
    should_not allow_value('NOTASEQUNCEOFACGTS').for(:sequence)
    should validate_numericality_of(:start).only_integer.is_greater_than(0)
    should validate_numericality_of(:end).only_integer.is_greater_than(0)


    should "Convert sequence to upper case" do
      crispr = TargRep::Crispr.new({:sequence => 'acgtacgtacgtacgtacgtacg', :chr => '1', :start =>1, :end =>2})
      crispr.save
      assert_equal crispr.sequence, 'ACGTACGTACGTACGTACGTACG'
    end
  end
end

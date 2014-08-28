# encoding: utf-8

require 'test_helper'

class TargRep::GenotypePrimerTest < ActiveSupport::TestCase
  context 'GenotypePrimer' do

    should belong_to(:mutagenesis_factor)
    should belong_to(:allele)

    should validate_presence_of :sequence
  end
end

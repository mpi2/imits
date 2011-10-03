# encoding: utf-8

require 'test_helper'

class MiAttempt::WarningGeneratorTest < ActiveSupport::TestCase
  context 'MiAttempt::WarningGenerator' do

    should 'generate warning if trying to create MI for already injected gene' do
      es_cell = Factory.create :es_cell_EPD0029_1_G04
      existing_mi = es_cell.mi_attempts.first

      mi = Factory.build :mi_attempt,
              :es_cell => Factory.create(:es_cell, :gene => existing_mi.es_cell.gene),
              :production_centre_name => existing_mi.production_centre_name,
              :consortium_name => existing_mi.consortium_name

      assert_true mi.generate_warnings

      assert_match /gene #{es_cell.gene.marker_symbol} has already been micro-injected/i, mi.warnings.first
    end

  end
end

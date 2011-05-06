# encoding: utf-8

require 'test_helper'

class CloneTest < ActiveSupport::TestCase
  context 'Clone' do
    setup do
      @clone = Factory.create :clone
    end

    should belong_to :pipeline
    should have_many :mi_attempts

    should have_db_column(:clone_name).with_options(:null => false)
    should have_db_index(:clone_name).unique(true)
    should validate_presence_of :clone_name
    should validate_uniqueness_of :clone_name

    should have_db_column(:marker_symbol).with_options(:null => false)
    should validate_presence_of :marker_symbol

    should have_db_column(:pipeline_id).with_options(:null => false)
    should validate_presence_of :pipeline

    should have_db_column(:allele_name_superscript_template).with_options(:null => false)
    should validate_presence_of :allele_name_superscript_template
    should have_db_column(:derivative_allele_suffix)

    context '#allele_name_superscript' do
      should 'work when d.a.s. is present' do
        @clone.derivative_allele_suffix = 'e'
        @clone.allele_name_superscript_template = 'tm1@(EUCOMM)Wtsi'
        assert_equal 'tm1e(EUCOMM)Wtsi', @clone.allele_name_superscript
      end

      should 'work when d.a.s. is not present' do
        @clone.derivative_allele_suffix = nil
        @clone.allele_name_superscript_template = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', @clone.allele_name_superscript
      end
    end

    context '#allele_name_superscript=' do
      should 'store a.n.s.t. and d.a.s. when d.a.s. is present' do
        @clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
        assert_equal 'tm2@(KOMP)Wtsi', @clone.allele_name_superscript_template
        assert_equal 'b', @clone.derivative_allele_suffix
      end

      should 'store a.n.s.t. only and null out d.a.s. when d.a.s. is not present' do
        @clone.allele_name_superscript = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', @clone.allele_name_superscript_template
        assert_equal nil, @clone.derivative_allele_suffix
      end

      should 'raise error if allele name superscript is not in a recognized format' do
        assert_raise Clone::AlleleNameSuperscriptFormatUnrecognizedError do
          @clone.allele_name_superscript = 'nonsense'
        end
      end
    end

  end
end

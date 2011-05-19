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

    context 'allele_name_superscript_template' do
      should 'have DB column' do
        assert_should have_db_column(:allele_name_superscript_template).with_options(:null => false)
      end

      should 'validate presence' do
        assert_should validate_presence_of :allele_name_superscript_template
      end

      should 'not be mass-assignable' do
        clone = Clone.new(:allele_name_superscript_template => 'nonsense')
        assert_nil clone.allele_name_superscript_template
      end
    end

    should have_db_column :allele_type

    context '#allele_name_superscript' do
      should 'work when allele_type is present' do
        @clone.allele_type = 'e'
        @clone.allele_name_superscript_template = 'tm1@(EUCOMM)Wtsi'
        assert_equal 'tm1e(EUCOMM)Wtsi', @clone.allele_name_superscript
      end

      should 'work when allele_type is not present' do
        @clone.allele_type = nil
        @clone.allele_name_superscript_template = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', @clone.allele_name_superscript
      end
    end

    context '#allele_name_superscript=' do
      should 'store a.n.s.t. and allele_type when allele name superscript includes an allele type letter' do
        @clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
        assert_equal 'tm2@(KOMP)Wtsi', @clone.allele_name_superscript_template
        assert_equal 'b', @clone.allele_type
      end

      should 'store a.n.s.t. only and null out allele_type when allele name superscript does not include an allele type letter' do
        @clone.allele_name_superscript = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', @clone.allele_name_superscript_template
        assert_equal nil, @clone.allele_type
      end

      should 'raise error if allele name superscript is not in a recognized format' do
        assert_raise Clone::AlleleNameSuperscriptFormatUnrecognizedError do
          @clone.allele_name_superscript = 'nonsense'
        end
      end
    end

    context '#allele_name' do
      should 'work' do
        @clone.allele_name_superscript = 'tm1a(EUCOMM)Wtsi'
        @clone.marker_symbol = 'Cbx1'
        assert_equal 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>', @clone.allele_name
      end
    end

    context '::update_or_create_from_marts_by_clone_name' do
      context 'for new clones' do
        should 'create clone with given name' do
          assert_nil Clone.find_by_clone_name 'HEPD0549_6_D02'
          clone = Clone.update_or_create_from_marts_by_clone_name 'HEPD0549_6_D02'
          assert_kind_of Clone, clone
          assert_kind_of Clone, Clone.find_by_clone_name('HEPD0549_6_D02')
          assert_equal 'C030046E11Rik', clone.marker_symbol
          assert_equal 'tm1a(EUCOMM)Hmgu', clone.allele_name_superscript
          assert_equal 'EUCOMM', clone.pipeline.name
          assert_equal 'MGI:1924893', clone.mgi_accession_id
        end
      end
    end

  end
end

# encoding: utf-8

require 'test_helper'

class CloneTest < ActiveSupport::TestCase
  context 'Clone' do

    def default_clone
      @default_clone ||= Factory.create :clone
    end

    context 'miscellaneous' do
      setup do
        assert_not_nil default_clone
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

      should 'have mgi_accession_id' do
        assert_should have_db_column(:mgi_accession_id).of_type(:text).with_options(:null => true)
      end
    end

    context '#allele_symbol_superscript_template' do
      should 'have DB column' do
        assert_should have_db_column(:allele_symbol_superscript_template).with_options(:null => true)
      end

      should 'not be mass-assignable' do
        clone = Clone.new(:allele_symbol_superscript_template => 'nonsense')
        assert_nil clone.allele_symbol_superscript_template
      end
    end

    should 'have #allele_type' do
      assert_should have_db_column :allele_type
    end

    context '#allele_symbol_superscript' do
      should 'work when allele_type is present' do
        default_clone.allele_type = 'e'
        default_clone.allele_symbol_superscript_template = 'tm1@(EUCOMM)Wtsi'
        assert_equal 'tm1e(EUCOMM)Wtsi', default_clone.allele_symbol_superscript
      end

      should 'work when allele_type is not present' do
        default_clone.allele_type = nil
        default_clone.allele_symbol_superscript_template = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_clone.allele_symbol_superscript
      end
    end

    context '#allele_symbol_superscript=' do
      should 'store a.n.s.t. and allele_type when allele name superscript includes an allele type letter' do
        default_clone.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        assert_equal 'tm2@(KOMP)Wtsi', default_clone.allele_symbol_superscript_template
        assert_equal 'b', default_clone.allele_type
      end

      should 'store a.n.s.t. only and null out allele_type when allele name superscript does not include an allele type letter' do
        default_clone.allele_symbol_superscript = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_clone.allele_symbol_superscript_template
        assert_equal nil, default_clone.allele_type
      end

      should 'set both a.n.s.t. and allele_type to nil when set to nil' do
        default_clone.allele_symbol_superscript = nil
        assert_equal nil, default_clone.allele_symbol_superscript_template
        assert_equal nil, default_clone.allele_type
      end

      should 'raise error if allele name superscript is not in a recognized format' do
        assert_raise Clone::AlleleSymbolSuperscriptFormatUnrecognizedError do
          default_clone.allele_symbol_superscript = 'nonsense'
        end
      end

      should 'recognise gene trap alleles' do
        default_clone.allele_symbol_superscript = 'Gt(IST12384G7)Tigm'
        assert_equal 'Gt(IST12384G7)Tigm', default_clone.allele_symbol_superscript_template
        assert_equal nil, default_clone.allele_type
      end
    end

    context '#allele_symbol' do
      should 'work' do
        default_clone.allele_symbol_superscript = 'tm1a(EUCOMM)Wtsi'
        default_clone.marker_symbol = 'Cbx1'
        assert_equal 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>', default_clone.allele_symbol
      end

      should 'be nil if allele_symbol_superscript is nil' do
        default_clone.allele_symbol_superscript = nil
        default_clone.marker_symbol = 'Trafd1'
        assert_nil default_clone.allele_symbol
      end
    end

    def assert_HEPD0549_6_D02_attributes(clone)
      assert_kind_of Clone, clone
      assert_kind_of Clone, Clone.find_by_clone_name('HEPD0549_6_D02')
      assert_equal 'C030046E11Rik', clone.marker_symbol
      assert_equal 'tm1a(EUCOMM)Hmgu', clone.allele_symbol_superscript
      assert_equal 'EUCOMM', clone.pipeline.name
      assert_equal 'MGI:1924893', clone.mgi_accession_id
    end

    context '::create_all_from_marts_by_clone_names' do
      should 'work for clones that it can find' do
        assert_equal 0, Clone.count
        clone_names = [
          'HEPD0549_6_D02',
          'EPD0127_4_E01'
        ]
        clones = Clone.create_all_from_marts_by_clone_names clone_names

        assert_equal 2, clones.size
        assert_equal clone_names.sort, clones.map(&:clone_name).sort

        clone = clones.first
        assert_HEPD0549_6_D02_attributes(clone)
      end

      should 'create pipelines if it needs to' do
        assert_nil Clone.find_by_clone_name 'EPD0555_1_E10'
        clones = Clone.create_all_from_marts_by_clone_names(['EPD0555_1_E10'])
        assert_equal 1, clones.size
        assert_kind_of Clone, clones.first
        assert_kind_of Clone, Clone.find_by_clone_name('EPD0555_1_E10')
        assert_equal 'KOMP-CSD', clones.first.pipeline.name
      end

      should 'skip those it cannot find' do
        clone_names = [
          'EUC0018f04',
          'EPD0127_4_E01'
        ]
        clones = Clone.create_all_from_marts_by_clone_names clone_names

        assert_equal 1, clones.size
        assert_equal ['EPD0127_4_E01'], clones.map(&:clone_name)
      end
    end

    context '::find_or_create_from_marts_by_clone_name' do
      should 'create clone from marts if it is not in the DB' do
        clone = Clone.find_or_create_from_marts_by_clone_name('HEPD0549_6_D02')
        assert_HEPD0549_6_D02_attributes(clone)
      end

      should 'return clone if it is already in the DB without hitting the marts' do
        Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        assert_equal 'EPD0127_4_E01', Clone.find_or_create_from_marts_by_clone_name('EPD0127_4_E01').clone_name
      end

      should 'return nil if it does not exist in DB or marts' do
        assert_nil Clone.find_or_create_from_marts_by_clone_name('EPD_NONEXISTENT')
      end

      should 'return nil if query was blank' do
        assert_nil Clone.find_or_create_from_marts_by_clone_name('')
      end
    end

    context '::get_clones_from_marts_by_clone_names' do
      should 'return clones data' do
        rows = Clone.get_clones_from_marts_by_clone_names(['EPD0127_4_E01', 'EPD0027_2_A01'])
        assert_equal 2, rows.size

        expected_clone = {
          'escell_clone' => 'EPD0127_4_E01',
          'pipeline' => 'EUCOMM',
          'production_qc_loxp_screen' => 'pass',
          'mutation_subtype' => 'conditional_ready',
          'marker_symbol' => 'Trafd1',
          'allele_symbol_superscript' => 'tm1a(EUCOMM)Wtsi',
          'mgi_accession_id' => 'MGI:1923551'
        }

        got = rows.find {|i| i['escell_clone'] == 'EPD0127_4_E01'}

        assert_equal expected_clone, got
      end
    end

    context '::get_clones_from_marts_by_marker_symbol' do
      should 'return sorted array of clone names with a valid marker symbol' do
        result = Clone.get_clones_from_marts_by_marker_symbol('cbx7')
        expected = %w{
          EPD0013_1_B05
          EPD0013_1_C05
          EPD0013_1_F05
          EPD0013_1_H05
          EPD0018_1_A07
          EPD0018_1_A08
          EPD0018_1_A09
          EPD0018_1_B07
          EPD0018_1_B08
          EPD0018_1_C07
          EPD0018_1_C08
          EPD0018_1_C09
          EPD0018_1_D08
          EPD0018_1_D09
          EPD0018_1_E08
          EPD0018_1_E09
          EPD0018_1_F07
          EPD0018_1_F08
          EPD0018_1_G07
          EPD0018_1_G08
          EPD0018_1_G09
          EPD0018_1_H07
          EPD0018_1_H08
          EPD0018_1_H09
        }
        assert_equal expected.sort, result.map {|i| i['escell_clone']}
      end

      should 'return empty array if it does not exist in DB or marts' do
        assert_equal [], Clone.get_clones_from_marts_by_marker_symbol('Nonexistent')
      end

      should 'return nil if query was blank' do
        assert_nil Clone.get_clones_from_marts_by_marker_symbol('')
      end

      should 'include attributes ES Cell Clone Name, Pipeline, Mutation Subtype, LoxP Screen' do
        expected = {
          'escell_clone' => 'EPD0127_4_E01',
          'pipeline' => 'EUCOMM',
          'production_qc_loxp_screen' => 'pass',
          'mutation_subtype' => 'conditional_ready',
          'marker_symbol' => 'Trafd1'
        }

        rows = Clone.get_clones_from_marts_by_marker_symbol('Trafd1')

        result = rows.find {|i| i['escell_clone'] == 'EPD0127_4_E01'}

        assert_equal expected, result
      end
    end

    context '::sync_all_from_marts' do
      should 'sync all clones that have incorrect data' do
        assert_equal 0, Clone.count
        clone_HEPD0549_6_D02 = Factory.create :clone,
                :clone_name => 'HEPD0549_6_D02',
                :marker_symbol => 'IAmWrong',
                :allele_symbol_superscript => 'tm1(WRONG)Wrong',
                :pipeline => Factory.create(:pipeline, :name => 'WRONG Pipeline'),
                :mgi_accession_id => 'MGI:WRONG'
        clone2 = Factory.create :clone, :clone_name => 'EPD0127_4_E01'

        Clone.sync_all_with_marts

        clone_HEPD0549_6_D02.reload; clone2.reload
        assert_HEPD0549_6_D02_attributes(clone_HEPD0549_6_D02)
        assert_equal 'Trafd1', clone2.marker_symbol
      end

      should 'ignore clones that cannot be found in the marts' do
        clone = Factory.create :clone, :clone_name => 'EPD_NONEXISTENT_1'

        Clone.sync_all_with_marts

        clone_copy = Clone.find_by_id!(clone.id)
        assert_equal clone, clone_copy
      end
    end

  end
end

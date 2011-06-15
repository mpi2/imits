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

      should 'have is_in_targ_rep flag' do
        assert_should have_db_column(:is_in_targ_rep).of_type(:boolean).with_options(:null => false, :default => false)
      end
    end

    context 'allele_name_superscript_template' do
      should 'have DB column' do
        assert_should have_db_column(:allele_name_superscript_template).with_options(:null => true)
      end

      should 'not be mass-assignable' do
        clone = Clone.new(:allele_name_superscript_template => 'nonsense')
        assert_nil clone.allele_name_superscript_template
      end
    end

    should have_db_column :allele_type

    context '#allele_name_superscript' do
      should 'work when allele_type is present' do
        default_clone.allele_type = 'e'
        default_clone.allele_name_superscript_template = 'tm1@(EUCOMM)Wtsi'
        assert_equal 'tm1e(EUCOMM)Wtsi', default_clone.allele_name_superscript
      end

      should 'work when allele_type is not present' do
        default_clone.allele_type = nil
        default_clone.allele_name_superscript_template = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_clone.allele_name_superscript
      end
    end

    context '#allele_name_superscript=' do
      should 'store a.n.s.t. and allele_type when allele name superscript includes an allele type letter' do
        default_clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
        assert_equal 'tm2@(KOMP)Wtsi', default_clone.allele_name_superscript_template
        assert_equal 'b', default_clone.allele_type
      end

      should 'store a.n.s.t. only and null out allele_type when allele name superscript does not include an allele type letter' do
        default_clone.allele_name_superscript = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_clone.allele_name_superscript_template
        assert_equal nil, default_clone.allele_type
      end

      should 'set both a.n.s.t. and allele_type to nil when set to nil' do
        default_clone.allele_name_superscript = nil
        assert_equal nil, default_clone.allele_name_superscript_template
        assert_equal nil, default_clone.allele_type
      end

      should 'raise error if allele name superscript is not in a recognized format' do
        assert_raise Clone::AlleleNameSuperscriptFormatUnrecognizedError do
          default_clone.allele_name_superscript = 'nonsense'
        end
      end

      should 'recognise gene trap alleles' do
        default_clone.allele_name_superscript = 'Gt(IST12384G7)Tigm'
        assert_equal 'Gt(IST12384G7)Tigm', default_clone.allele_name_superscript_template
        assert_equal nil, default_clone.allele_type
      end
    end

    context '#allele_name' do
      should 'work' do
        default_clone.allele_name_superscript = 'tm1a(EUCOMM)Wtsi'
        default_clone.marker_symbol = 'Cbx1'
        assert_equal 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>', default_clone.allele_name
      end
    end

    def assert_HEPD0549_6_D02_attributes(clone)
      assert_kind_of Clone, clone
      assert_kind_of Clone, Clone.find_by_clone_name('HEPD0549_6_D02')
      assert_equal 'C030046E11Rik', clone.marker_symbol
      assert_equal 'tm1a(EUCOMM)Hmgu', clone.allele_name_superscript
      assert_equal 'EUCOMM', clone.pipeline.name
      assert_equal 'MGI:1924893', clone.mgi_accession_id
      assert_equal true, clone.is_in_targ_rep?
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

    context '::find_or_create_from_mart' do
      should 'create clone from marts if it is not in the DB' do
        clone = Clone.find_or_create_from_mart('HEPD0549_6_D02')
        assert_HEPD0549_6_D02_attributes(clone)
        assert_equal 'EUCOMM', clone.pipeline.name
      end

      should 'return clone if it is already in the DB without hitting the marts' do
        Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        assert_equal 'EPD0127_4_E01', Clone.find_or_create_from_mart('EPD0127_4_E01').clone_name
      end

      should 'return nil if it does not' do
        Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        assert_nil Clone.find_or_create_from_mart('EPD_NONEXISTENT')
      end
    end

    context 'scope all_in_targ_rep' do
      should 'exist' do
        assert_equal 0, Clone.count
        clones_in_targ_rep = []
        5.times { clones_in_targ_rep << Factory.create(:clone, :is_in_targ_rep => true) }
        clones_not_in_targ_rep = []
        3.times { clones_not_in_targ_rep << Factory.create(:clone, :is_in_targ_rep => false) }

        result = Clone.all_in_targ_rep
        assert_equal 5, result.count
        assert_equal clones_in_targ_rep.sort_by(&:id), result.sort_by(&:id)
      end

      should 'sort by clone_name' do
        Factory.create(:clone, :clone_name => 'EPD002')
        Factory.create(:clone, :clone_name => 'EPD003')
        Factory.create(:clone, :clone_name => 'EPD001')

        assert_equal ['EPD001', 'EPD002', 'EPD003'], Clone.all_in_targ_rep.map(&:clone_name)
      end
    end

    context '::all_partitioned_by_marker_symbol' do
      should 'work' do
        Factory.create(:clone, :id => 1, :clone_name => 'EPD015', :marker_symbol => 'Cbx1')
        Factory.create(:clone, :id => 2, :clone_name => 'EPD002', :marker_symbol => 'Cbx1')
        Factory.create(:clone, :id => 3, :clone_name => 'EPD006', :marker_symbol => 'Trafd1')
        Factory.create(:clone, :id => 4, :clone_name => 'EPD003', :marker_symbol => 'Cbx7')
        Factory.create(:clone, :id => 5, :clone_name => 'EPD001', :marker_symbol => 'Trafd1')
        Factory.create(:clone, :id => 6, :clone_name => 'EPD009', :marker_symbol => 'Cbx1')

        clones = Clone.all_partitioned_by_marker_symbol

        assert_equal ['EPD002', 'EPD009', 'EPD015'], clones['Cbx1'].map(&:clone_name)
        assert_equal 1, clones['Cbx7'].size
        assert_equal 2, clones['Trafd1'].size
        assert_equal ['EPD001', 'EPD002', 'EPD003', 'EPD006', 'EPD009', 'EPD015'],
                clones[nil].map(&:clone_name)
      end

      should 'only select id, clone_name and marker_symbol' do
        Factory.create(:clone, :id => 1, :clone_name => 'EPD015', :marker_symbol => 'Cbx1')
        clone = Clone.all_partitioned_by_marker_symbol[nil].first
        assert_equal [1, 'EPD015', 'Cbx1'], [clone.id, clone.clone_name, clone.marker_symbol]
        assert_nil clone['mgi_accession_id']
      end
    end

  end
end

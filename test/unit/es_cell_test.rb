=begin
# encoding: utf-8

require 'test_helper'

class EsCellTest < ActiveSupport::TestCase
  context 'EsCell' do

    def default_es_cell
      @default_es_cell ||= Factory.create :es_cell
    end

    should 'have DB columns and associations' do
      assert_not_nil default_es_cell

      assert_should belong_to :pipeline
      assert_should have_many :mi_attempts
      assert_should belong_to :gene

      assert_should have_db_column(:name).with_options(:null => false)
      assert_should have_db_index(:name).unique(true)
      assert_should validate_presence_of :name
      assert_should validate_uniqueness_of :name

      assert_should have_db_column(:pipeline_id).with_options(:null => false)
      assert_should validate_presence_of :pipeline
      assert_should have_db_column(:parental_cell_line).with_options(:null => true)
      assert_should have_db_column(:mutation_subtype).of_type(:string).with_options(:limit => 100)
      assert_should have_db_column(:ikmc_project_id).of_type(:string).with_options(:limit => 100)
    end

    context '#allele_symbol_superscript_template' do
      should 'have DB column' do
        assert_should have_db_column(:allele_symbol_superscript_template).with_options(:null => true)
      end

      should 'not be mass-assignable' do
        es_cell = EsCell.new(:allele_symbol_superscript_template => 'nonsense')
        assert_nil es_cell.allele_symbol_superscript_template
      end
    end

    should 'have #allele_type' do
      assert_should have_db_column :allele_type
    end

    context '#allele_symbol_superscript' do
      should 'work when allele_type is present' do
        default_es_cell.allele_type = 'e'
        default_es_cell.allele_symbol_superscript_template = 'tm1@(EUCOMM)Wtsi'
        assert_equal 'tm1e(EUCOMM)Wtsi', default_es_cell.allele_symbol_superscript
      end

      should 'work when allele_type is not present' do
        default_es_cell.allele_type = nil
        default_es_cell.allele_symbol_superscript_template = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_es_cell.allele_symbol_superscript
      end
    end

    context '#allele_symbol_superscript=' do
      should 'store a.s.s.t. and allele_type when allele symbol superscript includes an allele type letter' do
        default_es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        assert_equal 'tm2@(KOMP)Wtsi', default_es_cell.allele_symbol_superscript_template
        assert_equal 'b', default_es_cell.allele_type
      end

      should 'store a.s.s.t. only and null out allele_type when allele symbol superscript does not include an allele type letter' do
        default_es_cell.allele_symbol_superscript = 'tm1(EUCOMM)Wtsi'
        assert_equal 'tm1(EUCOMM)Wtsi', default_es_cell.allele_symbol_superscript_template
        assert_equal nil, default_es_cell.allele_type
      end

      should 'set both a.s.s.t. and allele_type to nil when set to nil' do
        default_es_cell.allele_symbol_superscript = nil
        assert_equal nil, default_es_cell.allele_symbol_superscript_template
        assert_equal nil, default_es_cell.allele_type
      end

      should 'raise error if allele name superscript is not in a recognized format' do
        assert_raise EsCell::AlleleSymbolSuperscriptFormatUnrecognizedError do
          default_es_cell.allele_symbol_superscript = 'nonsense'
        end
      end

      should 'recognise gene trap alleles' do
        default_es_cell.allele_symbol_superscript = 'Gt(IST12384G7)Tigm'
        assert_equal 'Gt(IST12384G7)Tigm', default_es_cell.allele_symbol_superscript_template
        assert_equal nil, default_es_cell.allele_type
      end
    end

    context '#allele_symbol' do
      should 'work' do
        default_es_cell.allele_symbol_superscript = 'tm1a(EUCOMM)Wtsi'
        default_es_cell.gene.marker_symbol = 'Cbx1'
        assert_equal 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>', default_es_cell.allele_symbol
      end

      should 'be nil if allele_symbol_superscript is nil' do
        default_es_cell.allele_symbol_superscript = nil
        default_es_cell.gene.marker_symbol = 'Trafd1'
        assert_nil default_es_cell.allele_symbol
      end
    end

    context '#marker_symbol' do
      should 'be the gene marker symbol' do
        default_es_cell.gene.marker_symbol = 'Xyz1'
        assert_equal 'Xyz1', default_es_cell.marker_symbol
      end
    end

    def assert_HEPD0549_6_D02_attributes(es_cell)
      assert_kind_of EsCell, es_cell
      assert_kind_of EsCell, EsCell.find_by_name('HEPD0549_6_D02')
      assert_equal 'MGI:1924893', es_cell.gene.mgi_accession_id
      assert_equal 'C030046E11Rik', es_cell.gene.marker_symbol
      assert_equal 'tm1a(EUCOMM)Hmgu', es_cell.allele_symbol_superscript
      assert_equal 'EUCOMM', es_cell.pipeline.name
      assert_equal 'JM8A1.N3', es_cell.parental_cell_line
      assert_equal '27671', es_cell.ikmc_project_id
      assert_equal 'conditional_ready', es_cell.mutation_subtype
      assert_equal 10561, es_cell.allele_id
    end

    context '::create_es_cell_from_mart_data' do
      def create_test_es_cell
        EsCell.create_es_cell_from_mart_data(
          'escell_clone' => 'HEPD0549_6_D02',
          'marker_symbol' => 'C030046E11Rik',
          'allele_symbol_superscript' => 'tm1a(EUCOMM)Hmgu',
          'pipeline' => 'EUCOMM',
          'mgi_accession_id' => 'MGI:1924893',
          'parental_cell_line' => 'JM8A1.N3',
          'escell_ikmc_project_id' => '27671',
          'mutation_subtype' => 'conditional_ready',
          'allele_id' => 10561
        )
      end

      should 'work' do
        assert_nil Gene.find_by_marker_symbol 'C030046E11Rik'
        es_cell = create_test_es_cell
        assert_HEPD0549_6_D02_attributes(es_cell)
      end

      should 'create pipelines if it needs to' do
        assert_nil EsCell.find_by_name 'EPD0555_1_E10'
        es_cell = EsCell.find_or_create_from_marts_by_name('EPD0555_1_E10')
        assert_not_nil es_cell
        assert_equal 'KOMP-CSD', es_cell.pipeline.name
      end

      should 'work when gene already exists' do
        gene = Factory.create :gene, :marker_symbol => 'C030046E11Rik', :mgi_accession_id => 'MGI:1924893'
        es_cell = create_test_es_cell
        assert_equal gene, es_cell.gene
      end
    end

    context '::find_or_create_from_marts_by_name' do
      should 'create es_cell from marts if it is not in the DB' do
        assert_nil EsCell.find_by_name('HEPD0549_6_D02')
        es_cell = EsCell.find_or_create_from_marts_by_name('HEPD0549_6_D02')
        assert_HEPD0549_6_D02_attributes(es_cell)
      end

      should 'return es_cell if it is already in the DB without hitting the marts' do
        Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        assert_equal 'EPD0127_4_E01', EsCell.find_or_create_from_marts_by_name('EPD0127_4_E01').name
      end

      should 'return nil if it does not exist in DB or marts' do
        assert_nil EsCell.find_or_create_from_marts_by_name('EPD_NONEXISTENT')
      end

      should 'return nil if query was blank' do
        assert_nil EsCell.find_or_create_from_marts_by_name('')
      end
    end

    context '::get_es_cells_from_marts_by_names' do
      should 'return es_cells data' do
        rows = EsCell.get_es_cells_from_marts_by_names(['EPD0127_4_E01', 'EPD0027_2_A01'])
        assert_equal 2, rows.size

        expected_es_cell = {
          'escell_clone' => 'EPD0127_4_E01',
          'escell_ikmc_project_id' => '25489',
          'pipeline' => 'EUCOMM',
          'production_qc_loxp_screen' => 'pass',
          'mutation_subtype' => 'conditional_ready',
          'marker_symbol' => 'Trafd1',
          'allele_symbol_superscript' => 'tm1a(EUCOMM)Wtsi',
          'mgi_accession_id' => 'MGI:1923551',
          'parental_cell_line' => 'JM8.N4',
          'allele_id' => '10164'
        }

        got = rows.find {|i| i['escell_clone'] == 'EPD0127_4_E01'}

        assert_equal expected_es_cell, got
      end
    end

    context '::get_es_cells_from_marts_by_marker_symbol' do
      should 'return sorted array of es_cell names with a valid marker symbol' do
        result = EsCell.get_es_cells_from_marts_by_marker_symbol('cbx7')
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
        assert_equal [], EsCell.get_es_cells_from_marts_by_marker_symbol('Nonexistent')
      end

      should 'return nil if query was blank' do
        assert_nil EsCell.get_es_cells_from_marts_by_marker_symbol('')
      end

      should 'include attributes ES Cell Clone Name, Pipeline, Mutation Subtype, LoxP Screen' do
        expected = {
          'escell_clone' => 'EPD0127_4_E01',
          'pipeline' => 'EUCOMM',
          'production_qc_loxp_screen' => 'pass',
          'mutation_subtype' => 'conditional_ready',
          'marker_symbol' => 'Trafd1',
          'parental_cell_line' => 'JM8.N4'
        }

        rows = EsCell.get_es_cells_from_marts_by_marker_symbol('Trafd1')

        result = rows.find {|i| i['escell_clone'] == 'EPD0127_4_E01'}

        assert_equal expected, result
      end
    end

    context '::sync_all_from_marts' do
      should 'sync all es_cells that have incorrect data' do
        assert_equal 0, EsCell.count
        assert_equal 0, Gene.count

        gene = Factory.create :gene,
                :marker_symbol => 'IAmWrong',
                :mgi_accession_id => 'MGI:WRONG'
        es_cell_HEPD0549_6_D02 = Factory.create :es_cell,
                :name => 'HEPD0549_6_D02',
                :allele_symbol_superscript => 'tm1(WRONG)Wrong',
                :pipeline => Factory.create(:pipeline, :name => 'WRONG Pipeline'),
                :gene => gene
        es_cell2 = Factory.create :es_cell, :name => 'EPD0127_4_E01'

        EsCell.sync_all_with_marts

        es_cell_HEPD0549_6_D02.reload; es_cell2.reload
        assert_HEPD0549_6_D02_attributes(es_cell_HEPD0549_6_D02)
        assert_equal 'Trafd1', es_cell2.marker_symbol
      end

      should 'ignore es_cells that cannot be found in the marts' do
        es_cell = Factory.create :es_cell, :name => 'EPD_NONEXISTENT_1'

        EsCell.sync_all_with_marts

        es_cell_copy = EsCell.find_by_id!(es_cell.id)
        assert_equal es_cell, es_cell_copy
      end

      should 'raise error if an es cell has its gene changed and there are MiAttempts hanging off it' do
        mart_data = EsCell.get_es_cells_from_marts_by_names(['HEPD0549_6_D02'])[0]
        assert_equal 'C030046E11Rik', mart_data['marker_symbol']

        es_cell = Factory.create :es_cell, :name => 'HEPD0549_6_D02',
                :gene => Factory.create(:gene_cbx1)
        mi = Factory.create(:mi_attempt, :es_cell => es_cell)

        assert_raise(EsCell::SyncError) do
          EsCell.sync_all_with_marts
        end

        mi.reload
        assert_equal 'Cbx1', mi.es_cell.gene.marker_symbol
      end

      should 'only save an es_cell if it has changes' do
        es_cell_HEPD0549_6_D02 = Factory.create :es_cell,
                :name => 'HEPD0549_6_D02'
        EsCell.sync_all_with_marts

        EsCell.any_instance.expects(:save!).never
        EsCell.any_instance.expects(:update_attributes!).never

        EsCell.sync_all_with_marts
      end
    end

  end
end
=end

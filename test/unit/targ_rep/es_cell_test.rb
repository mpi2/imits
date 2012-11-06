require 'test_helper'

class TargRep::EsCellTest < ActiveSupport::TestCase

  context "TargRep::EsCell" do

    def default_es_cell
      @default_es_cell ||= Factory.create :es_cell
    end

    should 'have DB columns and associations' do

      assert_not_nil default_es_cell

      assert_should belong_to(:pipeline)
      assert_should belong_to(:allele)
      assert_should belong_to(:targeting_vector)

      assert_should have_many(:es_cell_qc_conflicts)
      assert_should have_many(:distribution_qcs)
      assert_should have_many(:mi_attempts)

      assert_should validate_uniqueness_of(:name)
      assert_should validate_presence_of(:name)
      assert_should validate_presence_of(:allele_id)

      pass_fail_only_qc_fields = [
        :production_qc_loss_of_allele,
        :production_qc_vector_integrity,
        :user_qc_five_prime_lr_pcr,
        :user_qc_three_prime_lr_pcr,
        :user_qc_map_test,
        :user_qc_tv_backbone_assay,
        :user_qc_loxp_confirmation,
        :user_qc_loss_of_wt_allele,
        :user_qc_neo_count_qpcr,
        :user_qc_lacz_sr_pcr,
        :user_qc_mutant_specific_sr_pcr,
        :user_qc_five_prime_cassette_integrity,
        :user_qc_neo_sr_pcr
        ]

      pass_fail_only_qc_fields.each do |qc_field|
        assert_should allow_value('pass').for(qc_field)
        assert_should allow_value('fail').for(qc_field)
        assert_should_not allow_value('wibble').for(qc_field)
      end

      pass_not_confirmed_qc_fields = [
        :production_qc_five_prime_screen,
        :production_qc_three_prime_screen,
        :production_qc_loxp_screen
      ]

      pass_not_confirmed_qc_fields.each do |qc_field|
        assert_should allow_value('pass').for(qc_field)
        assert_should allow_value('not confirmed').for(qc_field)
        assert_should_not allow_value('fail').for(qc_field)
        assert_should_not allow_value('wibble').for(qc_field)
      end

    end

    should "not be saved if it has empty attributes" do
      es_cell = Factory.build :invalid_escell

      assert !es_cell.valid?, "ES Cell validates an empty entry"
      assert !es_cell.save, "ES Cell validates the creation of an empty entry"
    end

    ##
    ## iMits compatibility tests
    ##

    context '#allele_symbol_superscript_template' do
      should 'have DB column' do
        assert_should have_db_column(:allele_symbol_superscript_template).with_options(:null => true)
      end

      should 'not be mass-assignable' do
        es_cell = TargRep::EsCell.new(:allele_symbol_superscript_template => 'nonsense')
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
        assert_raise TargRep::EsCell::AlleleSymbolSuperscriptFormatUnrecognizedError do
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
      assert_kind_of TargRep::EsCell, es_cell
      assert_kind_of TargRep::EsCell, TargRep::EsCell.find_by_name('HEPD0549_6_D02')
      assert_equal 'MGI:1924893', es_cell.gene.mgi_accession_id
      assert_equal 'C030046E11Rik', es_cell.gene.marker_symbol
      assert_equal 'tm1a(EUCOMM)Hmgu', es_cell.allele_symbol_superscript
      assert_equal 'EUCOMM', es_cell.pipeline.name
      assert_equal 'JM8A1.N3', es_cell.parental_cell_line
      assert_equal '27671', es_cell.ikmc_project_id
      assert_equal 'conditional_ready', es_cell.mutation_subtype
      assert_equal 10561, es_cell.allele_id
    end

    ##
    ##  Original TargRep tests
    ##

    should "not be saved if it has an incorrect MGI Allele ID" do
      es_cell = Factory.build :es_cell, :mgi_allele_id => 'WIBBLE'
      assert !es_cell.save, "An ES Cell is saved with an incorrect MGI Allele ID"
    end

    should "not be saved if it has molecular structure consistency issue" do
      targ_vec    = Factory.create :targeting_vector
      mol_struct  = Factory.create :allele

      es_cell = TargRep::EsCell.new({
        :name                => 'INVALID',
        :targeting_vector_id => targ_vec.id,
        :allele_id           => mol_struct.id
      })

      assert !es_cell.valid?, "ES Cell validates an invalid entry"
      assert !es_cell.save, "ES Cell validates the creation of an invalid entry"
    end

    should "copy the IKMC project id from it's TV if the project id is empty" do
      targ_vec = Factory.create :targeting_vector

      # ikmc_project_id is not provided
      es_cell = TargRep::EsCell.new({
        :name                => 'EPD001',
        :parental_cell_line  => 'JM8N4',
        :targeting_vector_id => targ_vec.id,
        :allele_id           => targ_vec.allele_id,
        :pipeline_id         => targ_vec.pipeline_id
      })

      assert es_cell.valid?, "ES Cell does not validate a valid entry"
      assert es_cell.save, "ES Cell does not validate the creation of a valid entry"
      assert es_cell.ikmc_project_id == targ_vec.ikmc_project_id, "ES Cell should have copied the ikmc_project_id from its targeting vector's"
    end

    should "cope gracefully if a user tries to send in an integer as an IKMC Project ID" do
      targ_vec = Factory.create :targeting_vector
      targ_vec.ikmc_project_id = "12345678"
      targ_vec.save

      es_cell = TargRep::EsCell.new({
        :name                => "EPD12345678",
        :parental_cell_line  => 'JM8N4',
        :ikmc_project_id     => 12345678,
        :targeting_vector_id => targ_vec.id,
        :allele_id           => targ_vec.allele_id,
        :pipeline_id         => targ_vec.pipeline_id
      })

      assert es_cell.valid?, "ES Cell does not validate a valid entry"
      assert es_cell.save, "ES Cell does not validate the creation of a valid entry"
    end

    should "set mirKO ikmc_project_ids to 'mirKO' + self.allele_id" do
      pipeline = TargRep::Pipeline.find_by_name!("mirKO")
      allele   = Factory.create :allele
      targ_vec = Factory.create :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => nil
      es_cell  = Factory.create :es_cell, :pipeline => pipeline, :allele => allele, :targeting_vector => targ_vec, :ikmc_project_id => nil
      assert_equal "mirKO#{ allele.id }", es_cell.ikmc_project_id
      assert_equal targ_vec.ikmc_project_id, es_cell.ikmc_project_id

      targ_vec2 = Factory.create :targeting_vector, :pipeline => pipeline, :allele => allele, :ikmc_project_id => 'mirKO'
      es_cell2  = Factory.create :es_cell, :pipeline => pipeline, :allele => allele, :ikmc_project_id => 'mirKO'
      assert_equal "mirKO#{ allele.id }", targ_vec2.ikmc_project_id
      assert_equal "mirKO#{ allele.id }", es_cell2.ikmc_project_id
    end

    should "set the ES cell strain correctly and validate the presence of the parental_cell_line" do
      es_cell = Factory.build :es_cell, :parental_cell_line => nil
      assert_false es_cell.valid?
      assert_false es_cell.save

      good_tests = {
        'JM8AN4'    => 'C57BL/6N-A<tm1Brd>/a',
        'JM8.AN3'   => 'C57BL/6N-A<tm1Brd>/a',
        'JM8N4'     => 'C57BL/6N',
        'JM8wibble' => 'C57BL/6N',
        'C2'        => 'C57BL/6N',
        'C2.2'      => 'C57BL/6N',
        'AB2.2'     => '129S7',
        'AB2.2a'    => '129S7',
        'SI2'       => '129S7',
        'SI2.2'     => '129S7',
        'SI6.C21'   => '129S7',
        'VGB6'      => 'C57BL/6N'
      }

      good_tests.each do |cell_line,expected_strain|
        es_cell = Factory.create :es_cell, :parental_cell_line => cell_line
        assert_equal expected_strain, es_cell.strain
      end

      ['JM4','wibble'].each do |cell_line|
        es_cell = Factory.build :es_cell, :parental_cell_line => cell_line
        assert_false es_cell.valid?
        assert_false es_cell.save
      end
    end
  end
end

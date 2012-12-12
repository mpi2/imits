# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create(:mi_attempt2,
        :blast_strain             => Strain.find_by_name!('BALB/c'),
        :colony_background_strain => Strain.find_by_name!('129P2/OlaHsd'),
        :test_cross_strain        => Strain.find_by_name!('129P2/OlaHsd')
      )
    end

    context 'misc attribute tests:' do

      should 'have es_cell' do
        assert_should have_db_column(:es_cell_id).with_options(:null => false)
        assert_should belong_to(:es_cell)
      end

      should 'have an mi_date' do
        assert_should have_db_column(:mi_date)
        assert_should validate_presence_of :mi_date
      end

      should 'have distribution centres' do
        assert_should have_many(:distribution_centres)
      end

      context '#status' do
        should 'exist' do
          assert_should have_db_column(:status_id).with_options(:null => false)
          assert_should belong_to(:status)
        end

        should 'be set to "Micro-injection in progress" by default' do
          assert_equal 'Micro-injection in progress', Factory.create(:mi_attempt2).status.name
        end

        should ', when changed, add a status stamp' do
          default_mi_attempt.update_attributes!(:is_active => false)
          assert_equal [MiAttempt::Status.micro_injection_in_progress, MiAttempt::Status.micro_injection_aborted],
                  default_mi_attempt.status_stamps.map(&:status)
        end

        should 'not be settable to non-genotype-confirmed if mi attempt has phenotype_attempts' do
          set_mi_attempt_genotype_confirmed(default_mi_attempt)
          Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
          default_mi_attempt.reload
          default_mi_attempt.is_active = false
          default_mi_attempt.valid?
          assert_match(/cannot be changed/i, default_mi_attempt.errors[:status].first)
        end
      end

      context '#status_stamps' do
        should 'be an association' do
          assert_should have_many :status_stamps
        end

        should 'always include a Micro-injection in progress status, even if MI is created in Genotype confirmed state' do
          mi = Factory.create :mi_attempt2_status_gtc
          assert_include mi.status_stamps.map {|i| i.status.code}, 'mip'
        end
      end

      context '#status_name' do
        should 'be filtered on #public_search' do
          default_mi_attempt.update_attributes!(:is_active => false)
          mi_attempt_2 = Factory.create :mi_attempt2_status_gtc
          mi_ids = MiAttempt.public_search(:status_name_ci_in => MiAttempt::Status.micro_injection_aborted.name).result.map(&:id)
          assert_include mi_ids, default_mi_attempt.id
          assert ! mi_ids.include?(mi_attempt_2.id)
        end
      end

      context '#add_status_stamp' do
        setup do
          default_mi_attempt.status_stamps.destroy_all
          default_mi_attempt.send(:add_status_stamp, MiAttempt::Status.micro_injection_aborted)
        end

        should 'add the stamp' do
          assert_not_nil MiAttempt::StatusStamp.where(
            :mi_attempt_id => default_mi_attempt.id,
            :status_id => MiAttempt::Status.micro_injection_aborted.id)
        end

        should 'update the association afterwards' do
          assert_equal [MiAttempt::Status.micro_injection_aborted],
                  default_mi_attempt.status_stamps.map(&:status)
        end
      end

      context '#reportable_statuses_with_latest_dates' do
        should 'work' do
          mi = Factory.create :mi_attempt2

          set_mi_attempt_genotype_confirmed(mi)
          replace_status_stamps(mi,
            :mip => '2011-01-01',
            :chr => '2011-01-02',
            :gtc => '2011-01-03'
          )
          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-01'),
            'Chimeras obtained' => Date.parse('2011-01-02'),
            'Genotype confirmed' => Date.parse('2011-01-03')
          }
          assert_equal expected, mi.reportable_statuses_with_latest_dates
        end
      end

      context '#mouse_allele_type' do
        should 'have mouse allele type column' do
          assert_should have_db_column(:mouse_allele_type)
        end

        should 'allow valid types' do
          [nil, 'a', 'b', 'c', 'd', 'e', '.1'].each do |i|
            assert_should allow_value(i).for :mouse_allele_type
          end
        end

        should 'not allow anything else' do
          ['f', 'A', '1', 'abc'].each do |i|
            assert_should_not allow_value(i).for :mouse_allele_type
          end
        end
      end

      context '#mouse_allele_symbol_superscript' do
        should 'be nil if mouse_allele_type is nil' do
          default_mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          default_mi_attempt.mouse_allele_type = nil
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'be nil if EsCell#allele_symbol_superscript_template and mouse_allele_type are nil' do
          default_mi_attempt.es_cell.allele_symbol_superscript = nil
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'be nil if EsCell#allele_symbol_superscript_template is nil and mouse_allele_type is not nil' do
          default_mi_attempt.es_cell.allele_symbol_superscript = nil
          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'work if mouse_allele_type is present' do
          default_mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal 'tm2e(KOMP)Wtsi', default_mi_attempt.mouse_allele_symbol_superscript
        end
      end

      context '#mouse_allele_symbol' do
        setup do
          @es_cell = Factory.create :es_cell_EPD0343_1_H06
          @mi_attempt = Factory.build :mi_attempt2, :es_cell => @es_cell
          @mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        end

        should 'be nil if mouse_allele_type is nil' do
          @mi_attempt.mouse_allele_type = nil
          assert_equal nil, @mi_attempt.mouse_allele_symbol
        end

        should 'work if mouse_allele_type is present' do
          @mi_attempt.mouse_allele_type = 'e'
          assert_equal 'Myo1c<sup>tm2e(KOMP)Wtsi</sup>', @mi_attempt.mouse_allele_symbol
        end

        should 'be nil if es_cell.allele_symbol_superscript is nil, even if mouse_allele_type is set' do
          @es_cell.allele_symbol_superscript = nil
          @es_cell.save!
          @mi_attempt.es_cell.reload
          @mi_attempt.mouse_allele_type = 'e'
          assert_nil @mi_attempt.mouse_allele_symbol
        end
      end

      context '#allele_symbol' do
        setup do
          @es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        end

        should 'return the mouse_allele_symbol if mouse_allele_type is set' do
          mi = Factory.build :mi_attempt2, :mouse_allele_type => 'b',
                  :es_cell => @es_cell
          assert_equal 'Trafd1<sup>tm1b(EUCOMM)Wtsi</sup>', mi.allele_symbol
        end

        should 'return the es_cell.allele_symbol if mouse_allele_type is not set' do
          mi = Factory.build :mi_attempt2, :mouse_allele_type => nil,
                  :es_cell => @es_cell
          assert_equal 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>', mi.allele_symbol
        end

        should 'return "" regardless if es_cell has no allele_symbol_superscript' do
          es_cell = Factory.create :es_cell, :gene => Factory.create(:gene_cbx1),
                  :allele_symbol_superscript => nil
          assert_equal nil, es_cell.allele_symbol_superscript

          mi = Factory.build :mi_attempt2, :mouse_allele_type => 'c',
                  :es_cell => es_cell
          assert_equal nil, mi.allele_symbol
        end
      end

      context 'strain tests:' do
        should 'have a blast strain' do
          assert_equal 'BALB/c', default_mi_attempt.blast_strain.name
        end

        should 'have a colony background strain' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.colony_background_strain.name
        end

        should 'have a test cross strain' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.test_cross_strain.name
        end

        should 'get and assign blast strain via AccessAssociationByAttribute' do
          default_mi_attempt.update_attributes!(:blast_strain_name => 'BALB/cAm')
          assert_equal 'BALB/cAm', default_mi_attempt.blast_strain_name
        end

        should 'get and assign colony background strain via AccessAssociationByAttribute' do
          default_mi_attempt.update_attributes!(:colony_background_strain_name => 'C57BL/6J')
          assert_equal 'C57BL/6J', default_mi_attempt.colony_background_strain_name
        end

        should 'get and assign test cross strain via AccessAssociationByAttribute' do
          default_mi_attempt.update_attributes!(:test_cross_strain_name => 'C57BL/6NTac/USA')
          default_mi_attempt.reload
          assert_equal 'C57BL/6NTac/USA', default_mi_attempt.test_cross_strain_name
        end

        should 'allow setting blast strain to nil using blast_strain_name' do
          default_mi_attempt.update_attributes!(:blast_strain_name => '')
          assert_nil default_mi_attempt.blast_strain
        end
      end

      context 'QC field tests:' do
        MiAttempt::QC_FIELDS.each do |qc_field|
          should "include #{qc_field}" do
            assert_should belong_to(qc_field)
          end

          should "have #{qc_field}_result association accessor" do
            default_mi_attempt.send("#{qc_field}_result=", 'pass')
            assert_equal 'pass', default_mi_attempt.send("#{qc_field}_result")

            default_mi_attempt.send("#{qc_field}_result=", 'na')
            assert_equal 'na', default_mi_attempt.send("#{qc_field}_result")
          end

          should "default to 'na' if #{qc_field} is assigned a blank" do
            default_mi_attempt.send("#{qc_field}_result=", '')
            assert default_mi_attempt.valid?
            assert_equal 'na', default_mi_attempt.send("#{qc_field}_result")
            assert_equal 'na', default_mi_attempt.send(qc_field).try(:description)
          end
        end
      end

      should 'have report_to_public' do
        assert_should have_db_column(:report_to_public).of_type(:boolean).with_options(:default => true, :null => false)
      end

      should 'have is_active' do
        assert_should have_db_column(:is_active).of_type(:boolean).with_options(:default => true, :null => false)
      end

      should 'have is_released_from_genotyping' do
        assert_should have_db_column(:is_released_from_genotyping).of_type(:boolean).with_options(:default => false, :null => false)
      end

      context '#colony_name' do
        should 'be unique' do
          default_mi_attempt.update_attributes!(:colony_name => 'ABCD')
          assert_should have_db_index(:colony_name).unique(true)
          assert_should validate_uniqueness_of :colony_name
        end

        should 'be unique (case insensitive)' do
          mi_attempt = Factory.create(:mi_attempt2,
            :colony_name => 'ABCD')
          mi_attempt2 = Factory.build(:mi_attempt2,
            :colony_name => 'abcd')

          mi_attempt2.valid?
          assert ! mi_attempt2.errors[:colony_name].blank?
        end

        should 'be auto-generated if not supplied' do
          es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
          plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'ICS', :gene => es_cell.gene)
          attributes = {
            :es_cell => es_cell,
            :colony_name => nil,
            :mi_plan => plan
          }
          mi_attempts = (1..3).to_a.map { Factory.create :mi_attempt2, attributes }
          mi_attempt_last = Factory.create :mi_attempt2, attributes.merge(:colony_name => 'MABC')

          assert_equal ['ICS-EPD0127_4_E01-1', 'ICS-EPD0127_4_E01-2', 'ICS-EPD0127_4_E01-3'],
                  mi_attempts.map(&:colony_name)
          assert_equal 'MABC', mi_attempt_last.colony_name
        end

        should 'not be auto-generated if es_cell was not assigned or found' do
          mi_attempt = Factory.build :mi_attempt2, :es_cell => nil, :colony_name => nil
          assert_false mi_attempt.valid?
          assert_nil mi_attempt.colony_name
        end

        should 'not be auto-generated if production centre was not assigned' do
          mi_plan = Factory.create :mi_plan
          assert_nil mi_plan.production_centre

          mi_attempt = Factory.build :mi_attempt2, :mi_plan => mi_plan, :colony_name => nil
          assert_false mi_attempt.valid?
          assert_nil mi_attempt.colony_name
        end

        should 'manage trimming and spacing' do
          colony_names = [
            { :old => "a_dummy_colony_name_with_no_spaces", :new => "a_dummy_colony_name_with_no_spaces" },
            { :old => "a dummy colony name with no dodgy spaces", :new => "a dummy colony name with no dodgy spaces" },
            { :old => " a \t dummy   colony name with  dodgy  \t\t  spaces ", :new => "a dummy colony name with dodgy spaces" }
          ]

          colony_names.each do |item|
            mi_attempt = Factory.create(:mi_attempt2, :colony_name => item[:old])
            mi_attempt.save!
            assert_equal item[:new], mi_attempt.colony_name
          end
        end

      end

      should 'have #comments' do
        mi = Factory.create :mi_attempt2, :comments => 'this is a comment'
        assert_equal 'this is a comment', mi.comments
      end

      context '#mi_plan' do
        should 'know about its new MiAttempt without having to be manually reloaded' do
          mi = Factory.create :mi_attempt2
          assert_equal [mi], mi.mi_plan.mi_attempts
        end

        should 'have a production centre' do
          mi_plan = Factory.create(:mi_plan)
          assert_nil mi_plan.production_centre
          mi = Factory.build :mi_attempt2, :mi_plan => mi_plan
          mi.valid?
          assert_equal ['must have a production centre (INTERNAL ERROR)'],
                  mi.errors['mi_plan']
        end
      end

      should 'have #updated_by column' do
        assert_should have_db_column(:updated_by_id).of_type(:integer)
      end

      should 'have #updated_by association' do
        user = Factory.create :user
        default_mi_attempt.updated_by_id = user.id
        assert_equal user, default_mi_attempt.updated_by
      end

      should 'have #phenotype_attempts' do
        assert_should have_many :phenotype_attempts
      end

      should 'have column genotyping_comment' do
        assert_should have_db_column(:genotyping_comment).of_type(:string).with_options(:null => true)
      end

    end # misc attribute tests

    context 'before filter' do
      context 'set_total_chimeras' do
        should 'work' do
          default_mi_attempt.total_male_chimeras = 5
          default_mi_attempt.total_female_chimeras = 4
          default_mi_attempt.save!
          default_mi_attempt.reload
          assert_equal 9, default_mi_attempt.total_chimeras
        end

        should 'deal with blank values' do
          default_mi_attempt.total_male_chimeras = nil
          default_mi_attempt.total_female_chimeras = nil
          default_mi_attempt.save!
          default_mi_attempt.reload
          assert_equal 0, default_mi_attempt.total_chimeras
        end
      end

      context '#set_blank_strings_to_nil (before validation)' do
        should 'work' do
          default_mi_attempt.total_male_chimeras = 1
          default_mi_attempt.mouse_allele_type = ' '
          default_mi_attempt.genotyping_comment = '  '
          default_mi_attempt.is_active = false
          default_mi_attempt.valid?
          assert_equal 1, default_mi_attempt.total_male_chimeras
          assert_equal nil, default_mi_attempt.mouse_allele_type
          assert_equal nil, default_mi_attempt.genotyping_comment
          assert_equal false, default_mi_attempt.is_active
        end
      end
    end

    context '#es_cell_name virtual attribute (TODO: move to Public::MiAttempt)' do
      setup do
        @trafd1 = Factory.create :gene_trafd1
        @es_cell_1 = Factory.create :es_cell, :name => 'EPD0127_4_E01', :gene => @trafd1
        @es_cell_2 = Factory.create :es_cell, :name => 'EPD0127_4_E02', :gene => @trafd1

        @mi_attempt = mi = Factory.build(:mi_attempt2, :mi_plan => TestDummy.mi_plan('MGP', 'WTSI', :gene => @trafd1))
        mi.es_cell_id = nil
        mi.es_cell = nil

        @mi_attempt.attributes = {:es_cell_name => 'EPD0127_4_E01'}
      end

      should 'be written on mass assignment when a new record' do
        assert_equal 'EPD0127_4_E01', @mi_attempt.es_cell_name
      end

      should 'be used to set the es_cell before save' do
        @mi_attempt.save!

        assert_equal 'EPD0127_4_E01', @mi_attempt.es_cell.name
      end

      should 'be overridden by the associated es_cell\'s name if that exists' do
        @mi_attempt.es_cell = @es_cell_2
        assert_equal @es_cell_2.name, @mi_attempt.es_cell_name
      end

      should 'not be settable if there is an associated es_cell' do
        @mi_attempt.es_cell = @es_cell_2
        @mi_attempt.es_cell_name = @es_cell_1.name
        assert_equal @es_cell_2.name, @mi_attempt.es_cell_name
      end

      should 'pull in es_cell from marts if it is not in the DB' do
        assert_equal nil, EsCell.find_by_name('EPD0127_4_E04')
        @mi_attempt.es_cell_name = 'EPD0127_4_E04'
        @mi_attempt.save!

        assert EsCell.find_by_name('EPD0127_4_E04')
        assert_equal EsCell.find_by_name!('EPD0127_4_E04'), @mi_attempt.es_cell
      end

      should 'validate as missing if not set and es_cell is not set either' do
        @mi_attempt.es_cell_name = nil
        @mi_attempt.valid?
        assert_equal ['cannot be blank'], @mi_attempt.errors['es_cell_name']
      end

      should 'not validate as missing if not set but es_cell is set' do
        @mi_attempt.es_cell_name = nil
        @mi_attempt.es_cell = EsCell.find_by_name('EPD0127_4_E02')
        @mi_attempt.valid?
        assert @mi_attempt.errors['es_cell_name'].blank?
      end

      should 'validate when es_cell_name is not a valid es_cell in the marts' do
        mi_plan = Factory.create(:mi_plan_with_production_centre)
        mi_attempt = MiAttempt.new(:es_cell_name => 'EPD0127_4_Z99', :mi_plan => mi_plan)
        assert_false mi_attempt.valid?
        assert ! mi_attempt.errors[:es_cell_name].blank?
      end
    end

    context '#gene' do
      should 'delegate to mi_plan if that exists' do
        es_cell = Factory.create :es_cell
        plan = Factory.create :mi_plan, :gene => cbx1

        mi = Factory.build :mi_attempt2, :es_cell => es_cell, :mi_plan => plan
        assert_equal plan.gene, mi.gene
      end

      should 'delegate to es_cell if mi_plan does not exist but es_cell does' do
        es_cell = Factory.create :es_cell

        mi = Factory.build :mi_attempt2, :es_cell => es_cell, :mi_plan => nil
        assert_equal es_cell.gene, mi.gene
      end

      should 'be nil if neither mi_plan or es_cell exist' do
        mi = Factory.build :mi_attempt2, :es_cell => nil, :mi_plan => nil
        assert_equal nil, mi.gene
      end
    end

    context '#es_cell_marker_symbol' do
      should 'delegate to es_cell' do
        assert_equal default_mi_attempt.es_cell.marker_symbol, default_mi_attempt.es_cell_marker_symbol
      end
    end

    context '#es_cell_allele_symbol' do
      should 'delegate to es_cell' do
        assert_equal default_mi_attempt.es_cell.allele_symbol, default_mi_attempt.es_cell_allele_symbol
      end
    end

    should 'validate that es_cell gene is the same as mi_plan gene' do
      mi = Factory.create :mi_attempt2
      mi.mi_plan.gene = Factory.create :gene

      mi.valid?
      assert_match(/gene mismatch/i, mi.errors[:base].join('; '))
    end

    context '::active' do
      should 'work' do
        10.times { Factory.create :mi_attempt2 }
        10.times { Factory.create :mi_attempt2, :is_active => false }
        assert_equal MiAttempt.where(:is_active => true).count, MiAttempt.active.count
        assert_equal 10, MiAttempt.active.count
      end
    end

    should 'have ::genotype_confirmed' do
      the_status = MiAttempt::Status.genotype_confirmed

      10.times do
        Factory.create :mi_attempt2_status_gtc
      end

      assert_equal 10, MiAttempt.where(:status_id => the_status.id).count
      assert_equal 10, MiAttempt.genotype_confirmed.count
    end

    should 'have ::in_progress' do
      the_status = MiAttempt::Status.micro_injection_in_progress

      10.times { Factory.create :mi_attempt2 }

      assert_equal 10, MiAttempt.where(:status_id => the_status.id).count
      assert_equal 10, MiAttempt.in_progress.count
    end

    should 'have ::aborted' do
      the_status = MiAttempt::Status.micro_injection_aborted

      10.times do
        mi = Factory.create :mi_attempt2
        mi.update_attributes!(:is_active => false)
      end

      assert_equal 10, MiAttempt.where(:status_id => the_status.id).count
      assert_equal 10, MiAttempt.aborted.count
    end

    context '::translate_public_param' do
      should 'translate marker_symbol' do
        assert_equal 'es_cell_gene_marker_symbol_eq',
                MiAttempt.translate_public_param('es_cell_marker_symbol_eq')
      end

      should 'translate allele symbol' do
        assert_equal 'es_cell_gene_allele_symbol_in',
                MiAttempt.translate_public_param('es_cell_allele_symbol_in')
      end

      should 'translate consortium_name' do
        assert_equal 'mi_plan_consortium_name_ci_in',
                MiAttempt.translate_public_param('consortium_name_ci_in')
      end

      should 'translate production_centre' do
        assert_equal 'mi_plan_production_centre_name_eq',
                MiAttempt.translate_public_param('production_centre_name_eq')
      end

      should 'leave other params untouched' do
        assert_equal 'colony_name_not_in',
                MiAttempt.translate_public_param('colony_name_not_in')
      end
    end

    context '::public_search' do
      should 'pass on parameters not needing translation to ::search' do
        assert_equal default_mi_attempt.id,
                MiAttempt.public_search(:colony_name_eq => default_mi_attempt.colony_name).result.first.id
      end

      should 'translate searching predicates' do
        es_cell = Factory.create :es_cell_EPD0127_4_E01
        Factory.create :es_cell_EPD0343_1_H06
        Factory.create :mi_attempt2, :mi_plan => TestDummy.mi_plan('ICS')
        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :gene => Gene.find_by_marker_symbol!('Trafd1')),
                :mi_plan => TestDummy.mi_plan('WTSI', 'Trafd1', :force_assignment => true)
        results = MiAttempt.public_search(:es_cell_marker_symbol_eq => 'Trafd1',
          :production_centre_name_eq => 'ICS').result

        es_cell.reload

        colony_names = es_cell.mi_attempts.map(&:colony_name)
        assert_equal colony_names.sort, results.map(&:colony_name).sort
      end
    end

    context '#production_centre' do
      should 'delegate to mi_plan' do
        assert_equal default_mi_attempt.mi_plan.production_centre,
                default_mi_attempt.production_centre
      end
    end

    context '#consortium' do
      should 'delegate to mi_plan' do
        assert_equal default_mi_attempt.mi_plan.consortium,
                default_mi_attempt.consortium
      end
    end

    context '#in_progress_date' do
      should 'return status stamp date for in progress status' do
        mi = Factory.create :mi_attempt2_status_gtc
        replace_status_stamps(mi,
          :chr => '2011-11-12 00:00 UTC',
          :mip => '2011-06-12 00:00 UTC',
          :gtc => '2011-01-24 00:00 UTC'
        )
        assert_equal Date.parse('2011-06-12'), mi.in_progress_date
      end
    end

    context '#create_phenotype_attempt_for_komp2' do
      should 'create a new phenotype attempt if status is genotype confirmed, attached to specific consortium and no current phenotype attempts' do
        this_consortium = Consortium.find_by_name!('BaSH')
        set_mi_attempt_genotype_confirmed(default_mi_attempt)
        default_mi_attempt.mi_plan.consortium = this_consortium
        default_mi_attempt.create_phenotype_attempt_for_komp2
        assert_equal 1, default_mi_attempt.phenotype_attempts.length
      end

      should 'not create a new phenotype attempt if status is genotype confirmed, attached to specific consortium and current phenotype attempts' do
        this_consortium = Consortium.find_by_name!('BaSH')
        set_mi_attempt_genotype_confirmed(default_mi_attempt)
        default_mi_attempt.mi_plan.consortium = this_consortium
        default_mi_attempt.phenotype_attempts.create!
        default_mi_attempt.create_phenotype_attempt_for_komp2
        assert_equal 1, default_mi_attempt.phenotype_attempts.length
      end
    end

    context '#distribution_centres_formatted_display' do
      should 'output a string of distribution centre and deposited material' do
        dc = TestDummy.create :mi_attempt_distribution_centre,
                'WTSI',
                'Live mice',
                :start_date => '2012-01-01',
                :end_date => '2012-01-02',
                :is_distributed_by_emma => true
        mi = dc.mi_attempt
        mi.reload
        assert_equal "[EMMA, WTSI, Live mice]", mi.distribution_centres_formatted_display
      end
    end

    context '#allele_id' do
      should 'return es_cell allele_id' do
        assert_equal default_mi_attempt.es_cell.allele_id, default_mi_attempt.allele_id
      end
    end

    should 'include HasStatuses' do
      assert_include default_mi_attempt.class.ancestors, ApplicationModel::HasStatuses
    end

    should 'have ::readable_name' do
      assert_equal 'micro-injection attempt', MiAttempt.readable_name
    end

    should 'handle template character in allele_symbol_superscript_template' do
      mi_attempt = Factory.create(:mi_attempt2)

      assert(/Auto\-generated Symbol \d+<sup>tm1a\(EUCOMM\)Wtsi<\/sup>/ =~ mi_attempt.allele_symbol)

      old_allele_symbol_superscript_template = mi_attempt.es_cell.allele_symbol_superscript_template
      mi_attempt.es_cell.allele_symbol_superscript_template = mi_attempt.es_cell.allele_symbol_superscript_template.gsub(/@/, '')

      mi_attempt.es_cell.save!

      assert_match(/Auto-generated Symbol \d+<sup>tm1\(EUCOMM\)Wtsi<\/sup>/, mi_attempt.allele_symbol)

      assert mi_attempt.es_cell.allele_symbol_superscript_template !~ /@/
      assert mi_attempt.allele_symbol !~ /@/

      mi_attempt.mouse_allele_type = nil
      mi_attempt.save!

      mi_attempt.es_cell.allele_symbol_superscript_template = old_allele_symbol_superscript_template

      mi_attempt.es_cell.save!

      assert mi_attempt.allele_symbol.length > 0

      assert_match(/Auto-generated Symbol \d+<sup>tm1a\(EUCOMM\)Wtsi<\/sup>/, mi_attempt.allele_symbol)

      assert mi_attempt.es_cell.allele_symbol_superscript_template =~ /@/
      assert mi_attempt.allele_symbol !~ /@/
    end

    should 'include BelongsToMiPlan' do
      assert_include MiAttempt.ancestors, ApplicationModel::BelongsToMiPlan
    end

  end
end

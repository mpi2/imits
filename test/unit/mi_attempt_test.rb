# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase

  def default_mi_attempt
    @default_mi_attempt ||= Factory.create(:mi_attempt2,
    :blast_strain             => Strain.find_by_name!('BALB/c'),
    :colony_background_strain => Strain.find_by_name!('129P2/OlaHsd'),
    :test_cross_strain        => Strain.find_by_name!('129P2/OlaHsd')
    )
  end

  def check_phenotype_attempt_status(mi, status_string)
    status = mi.relevant_phenotype_attempt_status(true)
    assert_equal status_string, status[:name]

    status = mi.relevant_phenotype_attempt_status(false)
    assert_nil status

    pa = mi.phenotype_attempts[0]
    pa.cre_excision_required = false
    pa.save!

    status = mi.relevant_phenotype_attempt_status(false)
    assert_equal status_string, status[:name]

    status = mi.relevant_phenotype_attempt_status(true)
    assert_nil status
  end

  MOUSE_ALLELE_OPTIONS = {
    nil => '[none]',
    'a' => 'a - Knockout-first - Reporter Tagged Insertion',
    'b' => 'b - Knockout-First, Post-Cre - Reporter Tagged Deletion',
    'c' => 'c - Knockout-First, Post-Flp - Conditional',
    'd' => 'd - Knockout-First, Post-Flp and Cre - Deletion, No Reporter',
    'e' => 'e - Targeted Non-Conditional',
    'e.1' => 'e.1 - Promoter excision from tm1e mouse',
    '.1' => '.1 - Promoter excision from Deletion'
  }.freeze

  context 'MiAttempt' do

    context 'Associations' do
      belongs_to_fields = [:mi_plan,
                           :es_cell,
                           :status,
                           :updated_by,
                           :blast_strain,
                           :colony_background_strain,
                           :test_cross_strain,
                           :mutagenesis_factor,
                           MiAttempt::QC_FIELDS
                           ].flatten

      have_many_fields =   [:crisprs,
                            :status_stamps,
                            :phenotype_attempts,
                            :distribution_centres,
                            :mouse_allele_mods,
                            :colonies
                           ]

      has_one_fields =     [:colony]

      belongs_to_fields.each do |field|
        should belong_to(field)
      end

      have_many_fields.each do |field|
        should have_many(field)
      end

      has_one_fields.each do |field|
        should have_one(field)
      end
    end

    context 'Validation' do
      should validate_presence_of(:mi_date)

      should ensure_inclusion_of(:mouse_allele_type).in_array(MOUSE_ALLELE_OPTIONS.keys)

      context 'uniqueness' do
        setup do
          Factory.create(:mi_attempt2)
        end

        context 'external_ref' do
          should 'be unique' do
            default_mi_attempt.update_attributes!(:external_ref => 'ABCD')
            assert_should have_db_index(:external_ref).unique(true)
            assert_should validate_uniqueness_of :external_ref
          end

          should 'be unique (case insensitive)' do
            mi_attempt = Factory.create(:mi_attempt2,
            :external_ref => 'ABCD')
            mi_attempt2 = Factory.build(:mi_attempt2,
            :external_ref => 'abcd')

            mi_attempt2.valid?
            assert ! mi_attempt2.errors[:external_ref].blank?
          end
        end
      end

      context 'require either an es_cell or mutagenesis factor' do
        setup do
          @mi = Factory.build(:mi_attempt)
          Factory.create(:es_cell, :allele => Factory.create(:allele, :gene_id => @mi.mi_plan.gene_id))
        end

        should 'be invalid if both are missing' do
          assert_false @mi.valid?
          assert_true @mi.errors.messages[:base].include?('Please Select EITHER an es_cell_name OR mutagenesis_factor')
        end

        should 'be invalid if both are present' do
          @mi.es_cell = TargRep::EsCell.first
          @mi.mutagenesis_factor = Factory.create(:mutagenesis_factor)

          assert_false @mi.valid?
          assert_true @mi.errors.messages[:base].include?('Please Select EITHER an es_cell_name OR mutagenesis_factor')
        end

        should 'be valid if es_cell is present' do
          @mi.es_cell = TargRep::EsCell.first

          assert_true @mi.valid?
        end

        should 'be valid if mutagenesis_factor is present' do
          crispr_plan = Factory.create(:crispr_plan)
          mi = Factory.build(:mi_attempt, :mi_plan => crispr_plan)
          mi.mutagenesis_factor = Factory.create(:mutagenesis_factor)

          assert_true mi.valid?
        end
      end

      should 'not allow es_cell mi_attempt to be assigned to a crispr plan' do
        crispr_plan = Factory.create(:crispr_plan)
        mi = Factory.build(:mi_attempt2, :mi_plan => crispr_plan)

        assert_false mi.valid?
        assert_true mi.errors.messages[:base].include?('MiAttempt cannot be assigned to this MiPlan. (crispr plan)')
      end

      should 'not allow crispr mi_attempt to be assigned to a non crispr plan' do
        es_cell_plan = Factory.create(:mi_plan_with_production_centre)
        mi = Factory.build(:mi_attempt_crispr, :mi_plan => es_cell_plan)

        assert_false mi.valid?
        assert_true mi.errors.messages[:base].include?('MiAttempt cannot be assigned to this MiPlan. (requires crispr plan)')
      end

      should 'not allow mi_attempt to be assigned to a phenotype only plan' do
        phenotype_only_plan = Factory.create(:mi_plan_phenotype_only)
        mi = Factory.build(:mi_attempt2_status_gtc, :mi_plan => phenotype_only_plan)

        assert_false mi.valid?
        assert_true mi.errors.messages[:base].include?('MiAttempt cannot be assigned to this MiPlan. (phenotype only)')
      end

      should 'not allow changes that result in a status change when the current mi_attempt status is Genotype Confirmed and phenotype attempts exist.' do
        mi = Factory.create(:phenotype_attempt).mi_attempt
        mi.reload
        mi.total_male_chimeras = 0

        assert_false mi.valid?
        assert_true mi.errors.messages[:status].include?('cannot be changed - phenotype attempts exist')
      end

    end

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


    context 'misc attribute tests:' do

      context 'Status' do
        should 'be set to "Micro-injection in progress" by default' do
          assert_equal 'Micro-injection in progress', Factory.create(:mi_attempt2).status.name # Es Cell Mi Attempt
          assert_equal 'Micro-injection in progress', Factory.create(:mi_attempt_crispr).status.name # Crispr Mi Attempt
        end

        should ', when changed, add a status stamp' do
          default_mi_attempt.update_attributes!(:is_active => false)
          assert_equal [MiAttempt::Status.micro_injection_in_progress, MiAttempt::Status.micro_injection_aborted],
          default_mi_attempt.status_stamps.map(&:status)
        end

        should 'always include a Micro-injection in progress status, even if MI is created in Genotype confirmed state' do
          mi = Factory.create :mi_attempt2_status_gtc
          assert_include mi.status_stamps.map {|i| i.status.code}, 'mip'
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
            :chr => '2011-01-02',
            :cof => '2011-01-02',
            :gtc => '2011-01-03'
            )
            expected = {
              'Micro-injection in progress' => mi.mi_date,
              'Chimeras obtained' => Date.parse('2011-01-02'),
              'Chimeras/Founder obtained' => Date.parse('2011-01-02'),
              'Genotype confirmed' => Date.parse('2011-01-03')
            }
            assert_equal expected, mi.reportable_statuses_with_latest_dates
          end
        end

        context '#in_progress_date' do
          should 'return status stamp date for in progress status which matches mi_date' do
            mi = Factory.create :mi_attempt2_status_gtc
            replace_status_stamps(mi,
              :chr => '2011-11-12 00:00 UTC',
              :mip => '2011-06-12 00:00 UTC', # this will be over written to match the mi_date
              :gtc => '2011-01-24 00:00 UTC'
            )
            assert_equal mi.mi_date, mi.in_progress_date
          end
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

        should 'be nil if TargRep::EsCell#allele_symbol_superscript_template and mouse_allele_type are nil' do
          default_mi_attempt.es_cell.allele_symbol_superscript = nil
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'be nil if TargRep::EsCell#allele_symbol_superscript_template is nil and mouse_allele_type is not nil' do
          es_cell = default_mi_attempt.es_cell
          es_cell.allele_symbol_superscript = nil
          es_cell.save!

          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'work if mouse_allele_type is present' do
          es_cell = default_mi_attempt.es_cell
          es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          es_cell.save!

          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal 'tm2e(KOMP)Wtsi', default_mi_attempt.mouse_allele_symbol_superscript
        end
      end

      context '#mouse_allele_symbol' do
        setup do
          @es_cell = Factory.create :es_cell_EPD0343_1_H06, :allele => Factory.create(:allele_with_gene_myolc)
          @mi_attempt = Factory.build :mi_attempt2, :es_cell => @es_cell
          @es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          @es_cell.save
        end


        should 'be nil if mouse_allele_type is nil, even if es_cell.allele_symbol_superscript is sets' do
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
          @es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
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
          es_cell = Factory.create :es_cell, :allele => Factory.create(:allele, :gene => cbx1),
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

        should 'have a blast strain mgi accession id' do
          assert_equal 'MGI:1', default_mi_attempt.blast_strain_mgi_accession
        end


        should 'have a blast strain mgi name' do
          assert_equal 'BALB/c', default_mi_attempt.blast_strain_mgi_name
        end

        should 'have a colony background strain' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.colony_background_strain.name
        end

        should 'have a colony background strain mgi accession id' do
          assert_equal 'MGI:28', default_mi_attempt.colony_background_strain_mgi_accession
        end

        should 'have a colony background strain mgi name' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.colony_background_strain_mgi_name
        end

        should 'have a test cross strain' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.test_cross_strain.name
        end

        should 'have a test cross strain mgi accession id' do
          assert_equal 'MGI:28', default_mi_attempt.test_cross_strain_mgi_accession
        end

        should 'have a test cross strain mgi name' do
          assert_equal '129P2/OlaHsd', default_mi_attempt.test_cross_strain_mgi_name
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
            # assert_equal 'na', default_mi_attempt.send(qc_field).try(:description)
          end

        end

        should "mouse_allele_type should be set to 'e' if qc_loxp_confirmation is set from pass to fail." do
          default_mi_attempt.qc_loxp_confirmation_result = 'fail'
          default_mi_attempt.save!

          assert_equal 'fail', default_mi_attempt.qc_loxp_confirmation_result
          assert_equal 'e', default_mi_attempt.mouse_allele_type

          default_mi_attempt.qc_loxp_confirmation_result = 'pass'
          default_mi_attempt.save!

          assert_equal 'pass', default_mi_attempt.qc_loxp_confirmation_result
          assert_equal nil, default_mi_attempt.mouse_allele_type

          allele = default_mi_attempt.allele
          allele.mutation_type_id = 4
          allele.save

          default_mi_attempt.reload
          default_mi_attempt.qc_loxp_confirmation_result = 'fail'
          default_mi_attempt.save

          assert_equal 'fail', default_mi_attempt.qc_loxp_confirmation_result
          assert_not_equal 'e', default_mi_attempt.mouse_allele_type
          assert_equal nil, default_mi_attempt.mouse_allele_type
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

        should 'return the external_ref' do
          default_mi_attempt.external_ref = 'NEW COLONY NAME'
          assert_equal 'NEW COLONY NAME', default_mi_attempt.colony_name
        end

        should 'set the external_ref' do
          external_ref = default_mi_attempt.external_ref
          default_mi_attempt.colony_name = 'NEW COLONY NAME'

          assert_equal 'NEW COLONY NAME', default_mi_attempt.external_ref
        end

        should 'not set the external_ref if the colony_name is equal to the old value when the external_ref is changed' do
          external_ref = default_mi_attempt.external_ref
          default_mi_attempt.external_ref = 'NEW COLONY NAME'
          default_mi_attempt.colony_name = external_ref

          assert_equal 'NEW COLONY NAME', default_mi_attempt.external_ref
          assert_not_equal external_ref, default_mi_attempt.colony_name
        end
      end

      context 'external_ref' do
        should 'be auto-generated if not supplied' do
          es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
          plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'ICS', :gene => es_cell.gene)

          attributes = {
            :es_cell => es_cell,
            :external_ref => nil,
            :mi_plan => plan
          }
          mi_attempts = (1..3).to_a.map { Factory.create :mi_attempt2, attributes }
          mi_attempt_last = Factory.create :mi_attempt2, attributes.merge(:external_ref => 'MABC')

          assert_equal ['ICS-EPD0127_4_E01-1', 'ICS-EPD0127_4_E01-2', 'ICS-EPD0127_4_E01-3'],
          mi_attempts.map(&:external_ref)
          assert_equal 'MABC', mi_attempt_last.external_ref
        end

        should 'not be auto-generated if es_cell was not assigned or found and mutagensis_factor is nil' do
          mi_attempt = Factory.build :mi_attempt2, :es_cell => nil, :external_ref => nil
          assert_false mi_attempt.valid?
          assert_nil mi_attempt.external_ref
        end

        should 'manage trimming and spacing' do
          external_refs = [
            { :old => "a_dummy_colony_name_with_no_spaces", :new => "a_dummy_colony_name_with_no_spaces" },
            { :old => "a dummy colony name with no dodgy spaces", :new => "a dummy colony name with no dodgy spaces" },
            { :old => " a \t dummy   colony name with  dodgy  \t\t  spaces ", :new => "a dummy colony name with dodgy spaces" }
          ]

          external_refs.each do |item|
            mi_attempt = Factory.create(:mi_attempt2, :external_ref => item[:old])
            mi_attempt.save!
            assert_equal item[:new], mi_attempt.external_ref
          end
        end

      end

      context 'colony association' do
        context 'for ES CELL mis' do
          should 'be created by default based on the external_ref' do
            mi = Factory.create :mi_attempt2

            assert_not_nil mi.colony
            assert_equal mi.external_ref, mi.colony.name
          end
          should 'have it\'s genotype_confirmed flag set to true if mi status changes to Genotype Confirmed' do
            mi = Factory.create :mi_attempt2_status_chr

            assert_false mi.colony.genotype_confirmed

            mi.number_of_het_offspring = 1
            mi.number_of_chimeras_with_glt_from_genotyping = 1
            mi.save

            assert_equal 'gtc', mi.status.code
            assert_true mi.colony.genotype_confirmed

          end
          should 'have it\'s genotype_confirmed flag set to false if mi status changes from Genotype Confirmed to Founders obtained (a low status)' do
            mi = Factory.create :mi_attempt2_status_gtc

            assert_true mi.colony.genotype_confirmed

            mi.number_of_het_offspring = 0
            mi.number_of_chimeras_with_glt_from_genotyping = 0
            mi.save

            assert_equal 'chr', mi.status.code
            assert_false mi.colony.genotype_confirmed
          end

          should "allow access of qc fields via mi_attempt accessors" do
            mi_with_es_cell = Factory.create :mi_attempt2

            # use setters
            MiAttempt::QC_FIELDS.each do |qc_field|
              mi_with_es_cell.send("#{qc_field}_result=", 'pass')
            end

            assert_true mi_with_es_cell.colony.colony_qc.save

            # test getters
            MiAttempt::QC_FIELDS.each do |qc_field|
              assert_equal 'pass', mi_with_es_cell.send("#{qc_field}_result")
            end
          end

        end

        context 'for Crispr mis' do
          should 'not exist' do
            mi = Factory.create :mi_attempt_crispr

            assert_nil mi.colony
          end

          should 'not exist even if there are multiple colonies' do
            mi = Factory.create :mi_attempt_crispr

            mi.colonies.new({:name => 'A_NEW_COLONY'})
            mi.colonies.new({:name => 'ANOTHER_NEW_COLONY'})
            mi.save

            assert_equal 2, mi.colonies.length
            assert_nil mi.colony
          end

          should 'allow creation of a colony via attributes' do
            # crisprs can have multiple colonies
            mi = Factory.create :mi_attempt_crispr, :colonies_attributes => [{ :name => 'test_colony', :genotype_confirmed => true }]
            assert_false mi.colonies.first.blank?
            assert_equal 'test_colony', mi.colonies.first.name
          end

        end
      end

      context 'colonies association' do
        context 'for ES CELL mis' do
          should 'not exist' do
            mi = Factory.create :mi_attempt2

            assert_not_nil mi.colony
            assert_equal [], mi.colonies
          end
          should 'colonies should not have a new method' do
            mi = Factory.create :mi_attempt2

            assert_raise(NoMethodError) do
              mi.colonies.new({:name => 'A_NEW_COLONY'})
            end
          end
        end

        context 'for Crisprs mis' do
          should 'not be created by default' do
            mi = Factory.create :mi_attempt_crispr
            assert_equal 0, mi.colonies.length
          end

          should 'allow multiple colonies to be created for the mi' do
            mi = Factory.create :mi_attempt_crispr
            mi.colonies.new({:name => 'A_NEW_COLONY'})
            mi.colonies.new({:name => 'ANOTHER_NEW_COLONY'})

            assert_equal 2, mi.colonies.length
          end
        end
      end

      should 'have #comments' do
        mi = Factory.create :mi_attempt2, :comments => 'this is a comment'
        assert_equal 'this is a comment', mi.comments
      end

      context 'cassette_transmission_verified' do
        context 'when automatically updated' do

          should 'set value to the genotype confirmed date' do
            mi_attempt = Factory.create :mi_attempt2_status_chr
            assert_equal mi_attempt.status.name, "Chimeras obtained"
            mi_attempt.is_released_from_genotyping = true
            mi_attempt.number_of_het_offspring = 1
            mi_attempt.number_of_chimeras_with_glt_from_genotyping = 1
            mi_attempt.save
            mi_attempt.reload

            assert_equal mi_attempt.status.name, "Genotype confirmed"
            assert mi_attempt.cassette_transmission_verified_auto_complete
            assert_equal mi_attempt.cassette_transmission_verified, mi_attempt.status_stamps.where("status_id = 2").first.created_at.to_date
          end

          should 'set the value to nil when mi_attempt changes to a status lower than genotype confirmed' do
            mi_attempt = Factory.create :mi_attempt2_status_gtc

            assert_equal mi_attempt.status.name, "Genotype confirmed"
            mi_attempt.is_released_from_genotyping = false
            mi_attempt.number_of_het_offspring = 0
            mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
            mi_attempt.save
            mi_attempt.reload

            assert_equal mi_attempt.status.name, "Chimeras obtained"
            assert_false mi_attempt.cassette_transmission_verified_auto_complete
            assert_nil mi_attempt.cassette_transmission_verified
          end
        end

        context 'when manually updated' do
          should 'NOT change value when mi_attempt becomes genotype confirmed' do
            mi_attempt = Factory.create :mi_attempt2_status_chr
            assert_equal mi_attempt.status.name, "Chimeras obtained"
            mi_attempt.cassette_transmission_verified = "2012/08/29"
            mi_attempt.is_released_from_genotyping = true
            mi_attempt.number_of_het_offspring = 1
            mi_attempt.number_of_chimeras_with_glt_from_genotyping = 1
            mi_attempt.save
            mi_attempt.reload

            assert_equal mi_attempt.status.name, "Genotype confirmed"
            assert_false mi_attempt.cassette_transmission_verified_auto_complete
            assert_not_equal mi_attempt.cassette_transmission_verified, "2012/08/29"
          end

          should 'NOT change value when mi_attempt changes to a status lower than genotype confirmed' do
            mi_attempt = Factory.create :mi_attempt2_status_gtc
            assert_equal mi_attempt.status.name, "Genotype confirmed"
            mi_attempt.cassette_transmission_verified = "2012/08/29"
            mi_attempt.is_released_from_genotyping = false
            mi_attempt.number_of_het_offspring = 0
            mi_attempt.number_of_chimeras_with_glt_from_genotyping = 0
            mi_attempt.save
            mi_attempt.reload

            assert_equal mi_attempt.status.name, "Chimeras obtained"
            assert_false mi_attempt.cassette_transmission_verified_auto_complete
            assert_not_equal mi_attempt.cassette_transmission_verified, "2012/08/29"
          end
        end
      end


      context '#mi_plan' do
        should 'know about its new MiAttempt without having to be manually reloaded' do
          mi = Factory.create :mi_attempt2
          assert_equal [mi], mi.mi_plan.mi_attempts
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

      should 'have column genotyping_comment' do
        assert_should have_db_column(:genotyping_comment).of_type(:string).with_options(:null => true)
      end

    end # misc attribute tests


    context '#es_cell_name virtual attribute (TODO: move to Public::MiAttempt)' do
      setup do
        allele = Factory.create(:allele_with_gene_trafd1)
        @trafd1 = allele.gene
        @es_cell_1 = Factory.create :es_cell, :name => 'EPD0127_4_E01', :allele => allele
        @es_cell_2 = Factory.create :es_cell, :name => 'EPD0127_4_E02', :allele => allele

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
        @mi_attempt.es_cell_name = @es_cell_2.name
        assert_equal @es_cell_2.name, @mi_attempt.es_cell_name
      end

      should 'not validate as missing if not set but es_cell is set' do
        @mi_attempt.es_cell_name = nil
        @mi_attempt.es_cell = TargRep::EsCell.find_by_name('EPD0127_4_E02')
        @mi_attempt.valid?
        assert @mi_attempt.errors['es_cell_name'].blank?
      end

      should 'validate when es_cell_name is not a valid es_cell in TargRep' do
        mi_plan = Factory.create(:mi_plan_with_production_centre)
        mi_attempt = MiAttempt.new(:es_cell_name => 'EPD0127_4_Z99', :mi_plan => mi_plan)
        assert_false mi_attempt.valid?
        assert_true mi_attempt.errors.messages[:base].include?('Please Select EITHER an es_cell_name OR mutagenesis_factor')
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
        assert_equal 'es_cell_allele_gene_marker_symbol_eq',
        MiAttempt.translate_public_param('es_cell_marker_symbol_eq')
      end

      should 'translate allele symbol' do
        assert_equal 'es_cell_allele_symbol_in',
        MiAttempt.translate_public_param('es_cell_allele_symbol_in')
      end

      should 'translate consortium_name' do
        assert_equal 'mi_plan_consortium_name_ci_in',
        MiAttempt.translate_public_param('consortium_name_ci_in')
      end

      should 'translate colony_name' do
        assert_equal 'external_ref_eq',
        MiAttempt.translate_public_param('colony_name_eq')
      end

      should 'translate production_centre' do
        assert_equal 'mi_plan_production_centre_name_eq',
        MiAttempt.translate_public_param('production_centre_name_eq')
      end

      should 'leave other params untouched' do
        assert_equal 'id_not_in',
        MiAttempt.translate_public_param('id_not_in')
      end
    end

    context '::public_search' do
      should 'pass on parameters not needing translation to ::search' do
        assert_equal default_mi_attempt.id, MiAttempt.public_search(:id_eq => default_mi_attempt.id).result.first.id
      end

      should 'translate searching predicates' do
        allele = Factory.create(:allele_with_gene_trafd1)
        es_cell = Factory.create :es_cell_EPD0127_4_E01, :allele => allele
        Factory.create :es_cell_EPD0343_1_H06, :allele => Factory.create(:allele_with_gene_myolc)
        Factory.create :mi_attempt2, :mi_plan => TestDummy.mi_plan('ICS')
        Factory.create :mi_attempt2,
        :es_cell => Factory.create(:es_cell, :allele => allele),
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
        assert_equal "[#{mi.production_centre_name}, Live mice] [EMMA, WTSI, Live mice]", mi.distribution_centres_formatted_display
      end
    end

    context '#distribution_centre' do
      context 'when genotype confirmed' do
        should 'default to the production centre' do
          mi_plan = Factory.create(:mi_plan, :production_centre => Centre.find_by_name('BCM'))
          mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

          assert_equal 1, mi_attempt.distribution_centres.count

          distribution_centre = mi_attempt.distribution_centres.first
          assert_equal mi_attempt.production_centre, distribution_centre.centre
          assert_equal 'Live mice', distribution_centre.deposited_material.name
        end

        should 'default to the KOMP if production centre is UCD' do
          mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name('DTCC'), :production_centre => Centre.find_by_name('UCD'))
          mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

          assert_equal 1, mi_attempt.distribution_centres.count

          distribution_centre = mi_attempt.distribution_centres.first
          assert_equal 'KOMP Repo', distribution_centre.centre.name
          assert_equal 'Live mice', distribution_centre.deposited_material.name
        end

        should 'default the distribution network to CMMR if production centre is TCP and consortium_name is NorCOMM2' do
          mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name('NorCOMM2'), :production_centre => Centre.find_by_name('TCP'))
          mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

          assert_equal 1, mi_attempt.distribution_centres.count

          distribution_centre = mi_attempt.distribution_centres.first
          assert_equal mi_attempt.production_centre, distribution_centre.centre
          assert_equal 'CMMR', distribution_centre.distribution_network
          assert_equal 'Live mice', distribution_centre.deposited_material.name
        end

        should 'default to the centre to KOMP_Rep if production centre is TCP and consortium_name is DTCC' do
          mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name('DTCC'), :production_centre => Centre.find_by_name('TCP'))
          mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

          assert_equal 1, mi_attempt.distribution_centres.count

          distribution_centre = mi_attempt.distribution_centres.first
          assert_equal 'KOMP Repo', distribution_centre.centre.name
          assert_equal 'Live mice', distribution_centre.deposited_material.name
        end

        should 'default the distribution network to EMMA if production centre is WTSI and ES Cell pipeline is EUCOMM pr EUCOMMTolls' do
          es_cell_eucomm = Factory.create(:es_cell)
          es_cell_eucomm_tools = Factory.create(:es_cell, :pipeline => TargRep::Pipeline.find_by_name!('EUCOMMTools') )

          mi_plan_eucomm = Factory.create(:mi_plan, :production_centre => Centre.find_by_name('WTSI'), :gene => es_cell_eucomm.gene)
          mi_plan_eucomm_tools = Factory.create(:mi_plan, :production_centre => Centre.find_by_name('WTSI'), :gene => es_cell_eucomm_tools.gene)

          mi_attempt_eucomm = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan_eucomm, :es_cell => es_cell_eucomm
          mi_attempt_eucomm_tools = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan_eucomm_tools, :es_cell => es_cell_eucomm_tools

          assert_equal 1, mi_attempt_eucomm.distribution_centres.count
          distribution_centre = mi_attempt_eucomm.distribution_centres.first
          assert_equal mi_attempt_eucomm.production_centre, distribution_centre.centre
          assert_equal 'EMMA', distribution_centre.distribution_network
          assert_equal 'Live mice', distribution_centre.deposited_material.name

          assert_equal 1, mi_attempt_eucomm_tools.distribution_centres.count
          distribution_centre = mi_attempt_eucomm_tools.distribution_centres.first
          assert_equal mi_attempt_eucomm_tools.production_centre, distribution_centre.centre
          assert_equal 'EMMA', distribution_centre.distribution_network
          assert_equal 'Live mice', distribution_centre.deposited_material.name
        end
      end

      # context 'centre' do
      #   context 'when set to KOMP Repo' do
      #     should 'default back to production centre if distribution network is given' do
      #       mi_plan = Factory.create(:mi_plan, :consortium => Consortium.find_by_name('DTCC'), :production_centre => Centre.find_by_name('TCP'))
      #       mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

      #       mi_plan2 = Factory.create(:mi_plan, :consortium => Consortium.find_by_name('DTCC'), :production_centre => Centre.find_by_name('UCD'))
      #       mi_attempt2 = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan

      #       assert_equal 'KOMP Repo', mi_attempt.distribution_centres.first.centre.name
      #       assert_equal 'KOMP Repo', mi_attempt2.distribution_centres.first.centre.name

      #       distribution_centre =mi_attempt.distribution_centres.first
      #       distribution_centre.distribution_network = 'CMMR'
      #       distribution_centre.save

      #       mi_attempt.reload
      #       assert_equal mi_attempt.production_centre, mi_attempt.distribution_centres.first.centre

      #       distribution_centre =mi_attempt2.distribution_centres.first
      #       distribution_centre.distribution_network = 'EMMRRC'
      #       distribution_centre.save
      #       mi_attempt2.reload

      #       mi_attempt2.reload
      #       assert_equal mi_attempt2.production_centre, mi_attempt2.distribution_centres.first.centre
      #     end
      #   end
      # end
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

    context '#relevant_phenotype_attempt_status' do
      should 'just work' do
        gene = Factory.create :gene,
        :marker_symbol => 'Moo1',
        :mgi_accession_id => 'MGI:12345'

        allele = Factory.create :allele, :gene => gene

        plan = TestDummy.mi_plan('MGP', 'WTSI', :gene => gene, :force_assignment => true)

        mi = Factory.create :mi_attempt2_status_gtc,
        :es_cell => Factory.create(:es_cell, :allele => allele),
        :mi_plan => plan,
        :is_active => true

        mi.phenotype_attempts.create!

        mi.reload

        pa = mi.phenotype_attempts[0]
        pa.cre_excision_required = true
        pa.save!

        check_phenotype_attempt_status(mi, "Phenotype Attempt Registered")

        pa.cre_excision_required = true
        pa.rederivation_started = true
        pa.save!

        check_phenotype_attempt_status(mi, "Rederivation Started")

        pa.cre_excision_required = true
        pa.deleter_strain = DeleterStrain.first
        pa.save!

        check_phenotype_attempt_status(mi, "Cre Excision Started")

        pa.cre_excision_required = true
        pa.number_of_cre_matings_successful = 2
        pa.colony_background_strain = Strain.first
        pa.mouse_allele_type = 'b'
        pa.save!

        check_phenotype_attempt_status(mi, "Cre Excision Complete")

        pa.cre_excision_required = true
        pa.phenotyping_started = true
        pa.save!

        check_phenotype_attempt_status(mi, "Phenotyping Started")

        pa.cre_excision_required = true
        pa.phenotyping_complete = true
        pa.save!

        check_phenotype_attempt_status(mi, "Phenotyping Complete")

        ## add another pa to list

        pa.cre_excision_required = true
        pa.save!

        mi.phenotype_attempts.create!
        pa = mi.phenotype_attempts[1]
        pa.cre_excision_required = false
        pa.rederivation_started = true
        pa.save!

        assert_equal 2, mi.phenotype_attempts.size

        #        check_phenotype_attempt_status(mi, "Phenotyping Complete")

        status = mi.relevant_phenotype_attempt_status(true)
        assert_equal "Phenotyping Complete", status[:name]

        status = mi.relevant_phenotype_attempt_status(false)
        assert_equal "Rederivation Started", status[:name]

        pa = mi.phenotype_attempts[0]
        pa.cre_excision_required = false
        pa.save!

        pa = mi.phenotype_attempts[1]
        pa.cre_excision_required = true
        pa.save!

        status = mi.relevant_phenotype_attempt_status(false)
        assert_equal "Phenotyping Complete", status[:name]

        status = mi.relevant_phenotype_attempt_status(true)
        assert_equal "Rederivation Started", status[:name]
      end
    end
  end
end

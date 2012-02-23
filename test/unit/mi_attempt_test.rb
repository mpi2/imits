# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create( :mi_attempt,
        :blast_strain             => Strain::BlastStrain.find_by_name!('BALB/c'),
        :colony_background_strain => Strain::ColonyBackgroundStrain.find_by_name!('129P2/OlaHsd'),
        :test_cross_strain        => Strain::TestCrossStrain.find_by_name!('129P2/OlaHsd')
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

      context 'centres tests:' do
        should 'exist' do
          assert_should have_db_column(:distribution_centre_id)
          assert_should belong_to(:distribution_centre)
        end

        should 'validate presence of production_centre_name' do
          assert_should validate_presence_of :production_centre_name
        end

        should 'default distribution_centre to production_centre' do
          centre = Factory.create :centre
          mi = Factory.create :mi_attempt, :production_centre_name => centre.name
          assert_equal centre.name, mi.distribution_centre.name
        end

        should 'not overwrite distribution_centre with production_centre if former has already been set' do
          mi = Factory.create :mi_attempt,
                  :production_centre_name => 'WTSI',
                  :distribution_centre_name => 'ICS'
          assert_equal 'ICS', mi.distribution_centre_name
          assert_not_equal 'WTSI', mi.distribution_centre_name
        end

        should 'allow access to distribution centre via its name' do
          centre = Factory.create :centre, :name => 'New Centre'
          default_mi_attempt.update_attributes!(:distribution_centre_name => 'New Centre')
          assert_equal 'New Centre', default_mi_attempt.distribution_centre.name
        end
      end

      context '#mi_attempt_status' do
        should 'exist' do
          assert_should have_db_column(:mi_attempt_status_id).with_options(:null => false)
          assert_should belong_to(:mi_attempt_status)
        end

        should 'be set to "Micro-injection in progress" by default' do
          assert_equal 'Micro-injection in progress', Factory.create(:mi_attempt).mi_attempt_status.description
        end

        should 'not be overwritten if it is set explicitly' do
          mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.genotype_confirmed)
          assert_equal 'Genotype confirmed', mi_attempt.mi_attempt_status.description
        end

        should 'not be reset to default if assigning id' do
          local_mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.genotype_confirmed)
          local_mi_attempt.mi_attempt_status_id = MiAttemptStatus.genotype_confirmed.id
          local_mi_attempt.save!
          local_mi_attempt = MiAttempt.find(local_mi_attempt.id)
          assert_equal 'Genotype confirmed', local_mi_attempt.mi_attempt_status.description
        end

        should ', when changed, add a status stamp' do
          default_mi_attempt.update_attributes!(:is_active => false)
          assert_equal [MiAttemptStatus.micro_injection_in_progress, MiAttemptStatus.micro_injection_aborted],
                  default_mi_attempt.status_stamps.map(&:mi_attempt_status)
        end

        should ', when assigned the same as current status, not add a status stamp' do
          default_mi_attempt.mi_attempt_status = MiAttemptStatus.micro_injection_in_progress; default_mi_attempt.save!
          assert_equal [MiAttemptStatus.micro_injection_in_progress],
                  default_mi_attempt.status_stamps.map(&:mi_attempt_status)
        end

        should 'not be set to non-genotype-confirmed if mi attempt has phenotype_attempts' do
          set_mi_attempt_genotype_confirmed(default_mi_attempt)
          Factory.create :phenotype_attempt, :mi_attempt => default_mi_attempt
          default_mi_attempt.reload
          default_mi_attempt.is_active = false
          default_mi_attempt.valid?
          assert_match /cannot be changed/i, default_mi_attempt.errors[:mi_attempt_status].first
        end
      end

      context '#status_stamps' do
        should 'be an association' do
          assert_should have_many :status_stamps
        end

        should 'be ordered by created_at (soonest last)' do
          mi = Factory.create :mi_attempt_with_status_history
          assert_equal [
            MiAttemptStatus.micro_injection_in_progress,
            MiAttemptStatus.genotype_confirmed,
            MiAttemptStatus.micro_injection_aborted,
            MiAttemptStatus.genotype_confirmed].map(&:description), mi.status_stamps.map(&:description)
        end

        should 'always include a Micro-injection in progress status, even if MI is created in Genotype confirmed state' do
          mi = Factory.create :mi_attempt_genotype_confirmed
          gc_stamp = mi.status_stamps.last
          stamp = mi.status_stamps.all.find {|ss| ss.mi_attempt_status == MiAttemptStatus.micro_injection_in_progress}
          assert stamp
          assert_equal [stamp, gc_stamp], mi.status_stamps
        end
      end

      context '#status virtual attribute' do
        should 'be the description of the status of the MI' do
          mi = default_mi_attempt
          mi.mi_attempt_status = MiAttemptStatus.genotype_confirmed
          assert_equal 'Genotype confirmed', mi.status
        end

        should 'be nil when actual status association is nil' do
          default_mi_attempt.mi_attempt_status = nil
          assert_nil default_mi_attempt.status
        end

        should 'be filtered on #public_search' do
          default_mi_attempt.update_attributes!(:is_active => false)
          mi_attempt_2 = Factory.create :mi_attempt_genotype_confirmed
          mi_ids = MiAttempt.public_search(:status_ci_in => MiAttemptStatus.micro_injection_aborted.description).result.map(&:id)
          assert_include mi_ids, default_mi_attempt.id
          assert ! mi_ids.include?(mi_attempt_2.id)
        end
      end

      context '#add_status_stamp' do
        setup do
          default_mi_attempt.status_stamps.destroy_all
          default_mi_attempt.send(:add_status_stamp, MiAttemptStatus.micro_injection_aborted)
        end

        should 'add the stamp' do
          assert_not_nil MiAttempt::StatusStamp.where(
            :mi_attempt_id => default_mi_attempt.id,
            :mi_attempt_status_id => MiAttemptStatus.micro_injection_aborted.id)
        end

        should 'update the association afterwards' do
          assert_equal [MiAttemptStatus.micro_injection_aborted],
                  default_mi_attempt.status_stamps.map(&:mi_attempt_status)
        end
      end

      context '#reportable_statuses_with_latest_dates' do
        should 'work' do
          mi = Factory.create :mi_attempt
          mi.status_stamps.first.update_attributes!(:created_at => '2011-01-01 00:00:00 UTC')
          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-01')
          }
          assert_equal expected, mi.reportable_statuses_with_latest_dates

          mi.status_stamps.create!(:mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
            :created_at => '2011-01-02 23:59:59')
          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-02')
          }
          assert_equal expected, mi.reportable_statuses_with_latest_dates

          set_mi_attempt_genotype_confirmed(mi)
          mi.status_stamps.last.update_attributes!(:created_at => '2011-02-02 23:59:59')
          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-02'),
            'Genotype confirmed' => Date.parse('2011-02-02')
          }
          assert_equal expected, mi.reportable_statuses_with_latest_dates

          mi.is_active = false; mi.save!
          mi.status_stamps.last.update_attributes!(:created_at => '2011-03-02 00:00:00 UTC')
          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-02'),
            'Genotype confirmed' => Date.parse('2011-02-02'),
            'Micro-injection aborted' => Date.parse('2011-03-02')
          }
          assert_equal expected, mi.reportable_statuses_with_latest_dates
        end

        should 'not include aborted status if latest status is GC' do
          mi = Factory.create :mi_attempt
          mi.status_stamps.first.update_attributes!(:created_at => '2011-01-01 00:00:00 UTC')
          mi.is_active = false; mi.save!
          mi.status_stamps.last.update_attributes!(:created_at => '2011-02-02 00:00:00 UTC')
          set_mi_attempt_genotype_confirmed(mi)
          mi.status_stamps.last.update_attributes!(:created_at => '2011-03-02 23:59:59')

          expected = {
            'Micro-injection in progress' => Date.parse('2011-01-01'),
            'Genotype confirmed' => Date.parse('2011-03-02'),
          }

          assert_equal expected, mi.reportable_statuses_with_latest_dates
        end
      end

      context '#mouse_allele_type' do
        should 'have mouse allele type column' do
          assert_should have_db_column(:mouse_allele_type)
        end

        should 'allow valid types' do
          [nil, 'a', 'b', 'c', 'd', 'e'].each do |i|
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
          @mi_attempt = Factory.build :mi_attempt, :es_cell => @es_cell
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
          mi = Factory.build :mi_attempt, :mouse_allele_type => 'b',
                  :es_cell => @es_cell
          assert_equal 'Trafd1<sup>tm1b(EUCOMM)Wtsi</sup>', mi.allele_symbol
        end

        should 'return the es_cell.allele_symbol if mouse_allele_type is not set' do
          mi = Factory.build :mi_attempt, :mouse_allele_type => nil,
                  :es_cell => @es_cell
          assert_equal 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>', mi.allele_symbol
        end

        should 'return "" regardless if es_cell has no allele_symbol_superscript' do
          es_cell = Factory.create :es_cell, :gene => Factory.create(:gene_cbx1),
                  :allele_symbol_superscript => nil
          assert_equal nil, es_cell.allele_symbol_superscript

          mi = Factory.build :mi_attempt, :mouse_allele_type => 'c',
                  :es_cell => es_cell
          assert_equal nil, mi.allele_symbol
        end
      end

      context 'strain tests:' do
        should 'have a blast strain' do
          assert_equal Strain::BlastStrain, default_mi_attempt.blast_strain.class
          assert_equal 'BALB/c', default_mi_attempt.blast_strain.name
        end

        should 'have a colony background strain' do
          assert_equal Strain::ColonyBackgroundStrain, default_mi_attempt.colony_background_strain.class
          assert_equal '129P2/OlaHsd', default_mi_attempt.colony_background_strain.name
        end

        should 'have a test cross strain' do
          assert_equal Strain::TestCrossStrain, default_mi_attempt.test_cross_strain.class
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

        should 'not allow setting a blast strain if it is not of the correct type' do
          strain = Strain.create!(:name => 'Nonexistent Strain')
          mi = Factory.build(:mi_attempt, :blast_strain_name => strain.name)
          assert_false mi.valid?
          assert ! mi.errors[:blast_strain_name].blank?
        end

        should 'not allow setting a colony background strain if it is not of the correct type' do
          strain = Strain.create!(:name => 'Nonexistent Strain')
          mi = Factory.build(:mi_attempt, :colony_background_strain_name => strain.name)
          assert_false mi.valid?
          assert ! mi.errors[:colony_background_strain_name].blank?
        end

        should 'not allow setting a colony background strain if it is not of the correct type' do
          strain = Strain.create!(:name => 'Nonexistent Strain')
          mi = Factory.build(:mi_attempt, :test_cross_strain_name => strain.name)
          assert_false mi.valid?
          assert ! mi.errors[:test_cross_strain_name].blank?
        end

        should 'allow setting blast strain to nil using blast_strain_name' do
          default_mi_attempt.update_attributes!(:blast_strain_name => '')
          assert_nil default_mi_attempt.blast_strain
        end
      end

      should 'have emma columns' do
        assert_should have_db_column(:is_suitable_for_emma).of_type(:boolean).with_options(:null => false)
        assert_should have_db_column(:is_emma_sticky).of_type(:boolean).with_options(:null => false)
      end

      should 'set is_suitable_for_emma to false by default' do
        assert_equal false, default_mi_attempt.is_suitable_for_emma?
      end

      should 'set is_emma_sticky to false by default' do
        assert_equal false, default_mi_attempt.is_emma_sticky?
      end

      should 'on save set is_suitable_for_emma to false if is_active is false' do
        default_mi_attempt.is_active = false
        default_mi_attempt.is_suitable_for_emma = true
        default_mi_attempt.save!

        assert_equal false, default_mi_attempt.is_suitable_for_emma
      end

      context '#emma_status' do
        context 'on read' do
          should 'be suitable if is_suitable_for_emma=true and is_emma_sticky=false' do
            default_mi_attempt.is_suitable_for_emma = true
            default_mi_attempt.is_emma_sticky = false
            assert_equal 'suitable', default_mi_attempt.emma_status
          end

          should 'be unsuitable if is_suitable_for_emma=false and is_emma_sticky=false' do
            default_mi_attempt.is_suitable_for_emma = false
            default_mi_attempt.is_emma_sticky = false
            assert_equal 'unsuitable', default_mi_attempt.emma_status
          end

          should 'be suitable_sticky if is_suitable_for_emma=true and is_emma_sticky=true' do
            default_mi_attempt.is_suitable_for_emma = true
            default_mi_attempt.is_emma_sticky = true
            assert_equal 'suitable_sticky', default_mi_attempt.emma_status
          end

          should 'be unsuitable_sticky if is_suitable_for_emma=false and is_emma_sticky=true' do
            default_mi_attempt.is_suitable_for_emma = false
            default_mi_attempt.is_emma_sticky = true
            assert_equal 'unsuitable_sticky', default_mi_attempt.emma_status
          end
        end

        context 'on write' do
          should 'work for suitable' do
            default_mi_attempt.emma_status = 'suitable'
            default_mi_attempt.save!
            default_mi_attempt.reload
            assert_equal [true, false], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
          end

          should 'work for unsuitable' do
            default_mi_attempt.emma_status = 'unsuitable'
            default_mi_attempt.save!
            default_mi_attempt.reload
            assert_equal [false, false], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
          end

          should 'work for suitable_sticky' do
            default_mi_attempt.emma_status = 'suitable_sticky'
            default_mi_attempt.save!
            default_mi_attempt.reload
            assert_equal [true, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
          end

          should 'work for unsuitable_sticky' do
            default_mi_attempt.emma_status = 'unsuitable_sticky'
            default_mi_attempt.save!
            default_mi_attempt.reload
            assert_equal [false, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
          end

          should 'error for anything else' do
            assert_raise(MiAttempt::EmmaStatusError) do
              default_mi_attempt.emma_status = 'invalid'
            end
          end

          should 'set cause #emma_status to return the right value after being saved' do
            default_mi_attempt.emma_status = 'unsuitable_sticky'
            default_mi_attempt.save!
            default_mi_attempt.reload

            assert_equal [false, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
            assert_equal 'unsuitable_sticky', default_mi_attempt.emma_status
          end
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

          should 'default to "na" if assigned a blank' do
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
          mi_attempt = Factory.create( :mi_attempt,
            :blast_strain             => Strain::BlastStrain.find_by_name!('BALB/c'),
            :colony_background_strain => Strain::ColonyBackgroundStrain.find_by_name!('129P2/OlaHsd'),
            :test_cross_strain        => Strain::TestCrossStrain.find_by_name!('129P2/OlaHsd'),
            :colony_name => 'ABCD'
          )
          mi_attempt2 = Factory.build( :mi_attempt,
            :blast_strain             => Strain::BlastStrain.find_by_name!('BALB/c'),
            :colony_background_strain => Strain::ColonyBackgroundStrain.find_by_name!('129P2/OlaHsd'),
            :test_cross_strain        => Strain::TestCrossStrain.find_by_name!('129P2/OlaHsd'),
            :colony_name => 'abcd'
          )

          assert_false mi_attempt2.valid?, 'Expecting to catch non-unique colony_name'
        end

        should 'be auto-generated if not supplied' do
          es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
          attributes = {
            :es_cell => es_cell,
            :colony_name => nil,
            :consortium_name => 'EUCOMM-EUMODIC',
            :production_centre_name => 'ICS'
          }
          mi_attempts = (1..3).to_a.map { Factory.create :mi_attempt, attributes }
          mi_attempt_last = Factory.create :mi_attempt, attributes.merge(:colony_name => 'MABC')

          assert_equal ['ICS-EPD0127_4_E01-1', 'ICS-EPD0127_4_E01-2', 'ICS-EPD0127_4_E01-3'],
                  mi_attempts.map(&:colony_name)
          assert_equal 'MABC', mi_attempt_last.colony_name
        end

        should 'not be auto-generated if es_cell was not assigned or found' do
          mi_attempt = Factory.build :mi_attempt, :es_cell => nil, :colony_name => nil
          assert_false mi_attempt.save
          assert_nil mi_attempt.colony_name
        end

        should 'not be auto-generated if production centre was not assigned' do
          mi_plan    = Factory.create :mi_plan
          assert_nil mi_plan.production_centre

          mi_attempt = Factory.build :mi_attempt, :mi_plan => mi_plan, :colony_name => nil
          assert_false mi_attempt.save
          assert_nil mi_attempt.colony_name
        end
      end

      context '#deposited_material' do
        should 'be in DB' do
          assert_should have_db_column(:deposited_material_id).with_options(:null => false)
        end

        should 'default to "Frozen embryos" if nil' do
          mi = Factory.create :mi_attempt
          assert_equal 'Frozen embryos', mi.deposited_material_name
        end

        should 'default to "Frozen embryos" if blank' do
          mi = Factory.create :mi_attempt
          mi.update_attributes!(:deposited_material_name => '')
          assert_equal 'Frozen embryos', mi.deposited_material_name
        end

        should 'be association to DepositedMaterial' do
          assert_should belong_to :deposited_material
        end

        should 'be setup for access_association_by_attribute' do
          dm = DepositedMaterial.last
          default_mi_attempt.deposited_material_name = dm.name
          default_mi_attempt.save!
          assert_equal dm, default_mi_attempt.deposited_material
        end
      end

      should 'have #comments' do
        mi = Factory.create :mi_attempt, :comments => 'this is a comment'
        assert_equal 'this is a comment', mi.comments
      end

      context '#mi_plan' do
        should 'have a production centre' do
          mi_plan = Factory.create(:mi_plan)
          assert_nil mi_plan.production_centre
          mi = Factory.build :mi_attempt, :mi_plan => mi_plan, :production_centre_name => 'WTSI'
          mi.valid?
          assert_equal ['must have a production centre (INTERNAL ERROR)'],
                  mi.errors['mi_plan']
        end

        should ', be reactivated, when the associated mi_attempt is active' do
            mi_attempt = Factory.create :mi_attempt, :is_active => false
            mi_attempt.mi_plan.is_active = false
            mi_attempt.mi_plan.save!
            mi_attempt.is_active = true
            mi_attempt.save!
            mi_attempt.reload
            assert_equal true, mi_attempt.mi_plan.is_active?
        end

        context 'on create' do
          should 'be set to a matching MiPlan' do
            cbx1 = Factory.create :gene_cbx1
            mi_plan = Factory.create :mi_plan, :gene => cbx1,
                    :consortium => Consortium.find_by_name!('BaSH'),
                    :production_centre => Centre.find_by_name!('WTSI'),
                    :status => MiPlan::Status.find_by_name!('Interest')

            Factory.create :mi_plan, :gene => cbx1,
                    :consortium => Consortium.find_by_name!('BaSH'),
                    :production_centre => nil,
                    :status => MiPlan::Status.find_by_name!('Interest')

            mi_attempt = Factory.build :mi_attempt,
                    :es_cell => Factory.create(:es_cell, :gene => cbx1),
                    :production_centre_name => mi_plan.production_centre.name,
                    :consortium_name => mi_plan.consortium.name,
                    :mi_plan => nil

            assert_no_difference("MiPlan.count") do
              mi_attempt.save!
            end

            assert_equal mi_plan, mi_attempt.mi_plan
          end

          should 'be know about its new MiAttempt without having to be manually reloaded' do
            mi = Factory.create :mi_attempt
            assert_equal [mi], mi.mi_plan.mi_attempts
          end

          should ', when assigning a matching MiPlan, set its status to Assigned if it is otherwise' do
            cbx1 = Factory.create :gene_cbx1
            mi_plan = Factory.create :mi_plan, :gene => cbx1,
                    :consortium => Consortium.find_by_name!('BaSH'),
                    :production_centre => Centre.find_by_name!('WTSI'),
                    :status => MiPlan::Status.find_by_name!('Interest')

            mi_attempt = Factory.build :mi_attempt,
                    :es_cell => Factory.create(:es_cell, :gene => cbx1),
                    :production_centre_name => mi_plan.production_centre.name,
                    :consortium_name => mi_plan.consortium.name,
                    :mi_plan => nil

            assert_no_difference("MiPlan.count") do
              mi_attempt.save!
            end

            mi_plan.reload
            assert_equal mi_plan, mi_attempt.mi_plan
            assert_equal 'Assigned', mi_plan.status.name
          end

          should 'be created if none match gene, consortium and production centre' do
            cbx1 = Factory.create :gene_cbx1
            assert_blank MiPlan.search(:production_centre_name_eq => 'WTSI',
              :consortium_name_eq => 'BaSH',
              :es_cell_gene_marker_symbol_eq => 'Cbx1').result

            mi_attempt = Factory.build :mi_attempt,
                    :es_cell => Factory.create(:es_cell, :gene => cbx1),
                    :mi_plan => nil
            mi_attempt.production_centre_name = 'WTSI'
            mi_attempt.consortium_name = 'BaSH'
            mi_attempt.save!

            assert_equal 1, MiPlan.search(:production_centre_name_eq => 'WTSI',
              :consortium_name_eq => 'BaSH',
              :es_cell_gene_marker_symbol_eq => 'Cbx1').result.count
            assert_equal 'Cbx1', mi_attempt.mi_plan.gene.marker_symbol
            assert_equal 'WTSI', mi_attempt.mi_plan.production_centre.name
            assert_equal 'BaSH', mi_attempt.mi_plan.consortium.name
            assert_equal 'High', mi_attempt.mi_plan.priority.name
            assert_equal 'Assigned', mi_attempt.mi_plan.status.name
          end

          should 'be assigned the MiPlan with specified consortium and gene but no production centre if an MiPlan with all 3 attributes does not exist - should also set the MiPlan\'s production centre to the one specified and mi_plan_status to Assigned' do
            assert_blank MiPlan.search(:production_centre_name_eq => 'WTSI',
              :consortium_name_eq => 'BaSH',
              :es_cell_gene_marker_symbol_eq => 'Cbx1').result

            cbx1 = Factory.create :gene_cbx1

            mi_plan = Factory.create :mi_plan, :gene => cbx1,
                    :consortium => Consortium.find_by_name!('BaSH'),
                    :production_centre => nil,
                    :status => MiPlan::Status.find_by_name!('Interest')

            mi_attempt = Factory.build :mi_attempt,
                    :es_cell => Factory.create(:es_cell, :gene => cbx1),
                    :production_centre_name => 'WTSI',
                    :consortium_name => mi_plan.consortium.name,
                    :mi_plan => nil

            assert_no_difference("MiPlan.count") do
              mi_attempt.save!
            end

            mi_plan.reload
            assert_equal mi_plan, mi_attempt.mi_plan
            assert_equal 'WTSI', mi_plan.production_centre.name
            assert_equal 'Assigned', mi_plan.status.name
          end
        end

        context 'on update' do
          setup do
            default_mi_attempt.mi_plan.status = MiPlan::Status['Inactive']
            default_mi_attempt.mi_plan.save!
            default_mi_attempt.update_attributes!(:is_active => false)
            default_mi_attempt.reload
          end

          should 'set its status to Assigned if MI attempt is becoming active again' do
            default_mi_attempt.update_attributes!(:is_active => true)
            default_mi_attempt.save!
            default_mi_attempt.reload
            assert_equal 'Assigned', default_mi_attempt.mi_plan.status.name
          end

          should 'not set its status to Assigned if MI attempt is not becoming active again' do
            default_mi_attempt.save!
            assert_equal 'Inactive', default_mi_attempt.mi_plan.status.name
          end
        end

        should 'not be allowed to be in state "Aborted - ES Cell QC Failed" for MiAttempt to be created against it' do
          gene = Factory.create :gene_cbx1
          mi_plan = Factory.create :mi_plan,
                  :gene => gene,
                  :consortium => Consortium.find_by_name!('BaSH'),
                  :number_of_es_cells_starting_qc => 5,
                  :number_of_es_cells_passing_qc => 0
          assert_equal 'Aborted - ES Cell QC Failed', mi_plan.status.name
          es_cell = Factory.create :es_cell, :gene => gene

          mi_attempt = Factory.build :mi_attempt, :es_cell => es_cell,
                  :consortium_name => mi_plan.consortium.name,
                  :production_centre_name => 'WTSI'

          mi_attempt.valid?

          assert_match 'ES cells failed QC', mi_attempt.errors[:base].join
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

      context 'set_blank_strings_to_nil' do
        should 'work' do
          default_mi_attempt.total_male_chimeras = 1
          default_mi_attempt.mouse_allele_type = ' '
          default_mi_attempt.is_active = false
          default_mi_attempt.save!
          default_mi_attempt.reload
          assert_equal 1, default_mi_attempt.total_male_chimeras
          assert_equal nil, default_mi_attempt.mouse_allele_type
          assert_equal false, default_mi_attempt.is_active
        end
      end
    end

    context '#es_cell_name virtual attribute' do
      setup do
        Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
        Factory.create :es_cell_EPD0343_1_H06_without_mi_attempts

        @mi_attempt = mi = Factory.build(:mi_attempt)
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
        @mi_attempt.es_cell = EsCell.find_by_name('EPD0343_1_H06')
        assert_equal 'EPD0343_1_H06', @mi_attempt.es_cell_name
      end

      should 'not be settable if there is an associated es_cell' do
        @mi_attempt.es_cell = EsCell.find_by_name('EPD0343_1_H06')
        @mi_attempt.es_cell_name = 'EPD0127_4_E01'
        assert_equal 'EPD0343_1_H06', @mi_attempt.es_cell_name
      end

      should 'pull in es_cell from marts if it is not in the DB' do
        @mi_attempt.es_cell_name = 'EPD0029_1_G04'
        @mi_attempt.save!

        assert_equal 'EPD0029_1_G04', @mi_attempt.es_cell_name
      end

      should 'validate as missing if not set and es_cell is not set either' do
        @mi_attempt.es_cell_name = nil
        @mi_attempt.valid?
        assert_equal ['cannot be blank'], @mi_attempt.errors['es_cell_name']
      end

      should 'not validate as missing if not set but es_cell is set' do
        @mi_attempt.es_cell_name = nil
        @mi_attempt.es_cell = EsCell.find_by_name('EPD0343_1_H06')
        @mi_attempt.valid?
        assert @mi_attempt.errors['es_cell_name'].blank?
      end

      should 'validate when es_cell_name is not a valid es_cell in the marts' do
        mi_plan = Factory.create(:mi_plan, :production_centre => Centre.first)
        mi_attempt = MiAttempt.new(:es_cell_name => 'EPD0127_4_G01', :mi_plan => mi_plan)
        assert_false mi_attempt.valid?
        assert ! mi_attempt.errors[:es_cell_name].blank?
      end
    end

    should 'have #gene' do
      es_cell = Factory.create :es_cell_EPD0343_1_H06
      mi = es_cell.mi_attempts.first
      assert_equal es_cell.gene, mi.gene
    end

    context '#consortium_name virtual attribute' do
      context 'when mi_plan exists' do
        should 'on get return mi_plan consortium name' do
          assert_equal default_mi_attempt.mi_plan.consortium.name, default_mi_attempt.consortium_name
        end

        should 'when set on update give validation error' do
          default_mi_attempt.consortium_name = 'Brand New Consortium'
          default_mi_attempt.valid?
          assert_equal ['cannot be changed'], default_mi_attempt.errors['consortium_name']
        end
      end

      context 'when mi_plan does not exist' do
        should 'on get return the assigned consortium_name' do
          mi = MiAttempt.new :consortium_name => 'Nonexistent Consortium'
          assert_equal 'Nonexistent Consortium', mi.consortium_name
        end

        should 'when set to nonexistent consortium and validated give error' do
          mi = MiAttempt.new :consortium_name => 'Nonexistent Consortium'
          mi.valid?
          assert_equal ['does not exist'], mi.errors['consortium_name']
        end

        should 'when set to a valid consortium and validated should not give error' do
          mi = MiAttempt.new :consortium_name => 'BaSH'
          mi.valid?
          assert_blank mi.errors['consortium_name']
        end
      end
    end

    context '#production_centre_name virtual attribute' do
      context 'when mi_plan exists' do
        should 'on get return mi_plan production_centre name' do
          assert_equal default_mi_attempt.mi_plan.production_centre.name, default_mi_attempt.production_centre_name
        end

        should 'when set on update give validation error' do
          default_mi_attempt.production_centre_name = 'Brand New Centre'
          default_mi_attempt.valid?
          assert_equal ['cannot be changed'], default_mi_attempt.errors['production_centre_name']
        end
      end

      context 'when mi_plan does not exist' do
        should 'on get return the assigned production_centre_name' do
          mi = MiAttempt.new :production_centre_name => 'Nonexistent Centre'
          assert_equal 'Nonexistent Centre', mi.production_centre_name
        end

        should 'when set to nonexistent production_centre and validated give error' do
          mi = MiAttempt.new :production_centre_name => 'Nonexistent Centre'
          mi.valid?
          assert_equal ['does not exist'], mi.errors['production_centre_name']
        end

        should 'when set to a valid production_centre and validated should not give error' do
          mi = MiAttempt.new :production_centre_name => 'ICS'
          mi.valid?
          assert_blank mi.errors['production_centre_name']
        end
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
      mi = Factory.create :mi_attempt
      mi.mi_plan.gene = Factory.create :gene

      mi.valid?
      assert_match /gene mismatch/i, mi.errors[:base].join('; ')
    end

    context '::active' do
      should 'work' do
        10.times { Factory.create( :mi_attempt ) }
        10.times { Factory.create( :mi_attempt, :is_active => false ) }
        assert_equal MiAttempt.where(:is_active => true).count, MiAttempt.active.count
        assert_equal 10, MiAttempt.active.count
      end
    end

    should 'have ::genotype_confirmed' do
      the_status = MiAttemptStatus.genotype_confirmed

      10.times do
        Factory.create :mi_attempt,
                :number_of_het_offspring => 12,
                :production_centre_name => 'ICS',
                :is_active => true
      end

      assert_equal 10, MiAttempt.where(:mi_attempt_status_id => the_status.id).count
      assert_equal 10, MiAttempt.genotype_confirmed.count
    end

    should 'have ::in_progress' do
      the_status = MiAttemptStatus.micro_injection_in_progress

      10.times { Factory.create :mi_attempt }

      assert_equal 10, MiAttempt.where(:mi_attempt_status_id => the_status.id).count
      assert_equal 10, MiAttempt.in_progress.count
    end

    should 'have ::aborted' do
      the_status = MiAttemptStatus.micro_injection_aborted

      10.times do
        mi = Factory.create :mi_attempt
        mi.update_attributes!(:is_active => false)
      end

      assert_equal 10, MiAttempt.where(:mi_attempt_status_id => the_status.id).count
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

      should 'translate status' do
        assert_equal 'mi_attempt_status_description_ci_in',
                MiAttempt.translate_public_param('status_ci_in')
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
        Factory.create :mi_attempt, :production_centre_name => 'ICS'
        Factory.create :mi_attempt, :es_cell => Factory.create(:es_cell, :gene => Gene.find_by_marker_symbol!('Trafd1'))
        results = MiAttempt.public_search(:es_cell_marker_symbol_eq => 'Trafd1',
          :production_centre_name_eq => 'ICS').result

        colony_names = es_cell.mi_attempts.map(&:colony_name)
        assert_equal colony_names.sort, results.map(&:colony_name).sort
      end

      should_eventually 'translate sorting predicates' do
        flunk 'Dependent on ransack enabling sorting by associations fields'
      end
    end

    context '#find_matching_mi_plan' do
      should 'return the MiPlan with production centre for this MiAttempt if it exists' do
        gene = Factory.create :gene_cbx1
        Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('BaSH'),
                :gene => gene
        mi_plan = Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => Centre.find_by_name!('WTSI'),
                :gene => gene
        es_cell = Factory.create(:es_cell, :gene => gene)

        mi = MiAttempt.new :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI',
                :es_cell_name => es_cell.name
        mi.valid? # does not matter if it passes or not, just want filters to fire

        assert_nil mi.mi_plan
        assert_equal mi_plan, mi.find_matching_mi_plan
      end

      should 'return the MiPlan without production centre for this MiAttempt, if one with does not exist' do
        gene = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('BaSH'),
                :gene => gene
        es_cell = Factory.create(:es_cell, :gene => gene)

        mi = MiAttempt.new :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI',
                :es_cell_name => es_cell.name
        mi.valid? # does not matter if it passes or not, just want filters to fire

        assert_nil mi.mi_plan
        assert_equal mi_plan, mi.find_matching_mi_plan
      end

      should 'return nil if gene is nil' do
        mi = MiAttempt.new
        assert_nil mi.find_matching_mi_plan
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
      should 'return earliest status stamp date for in progress status' do
        mi = Factory.create :mi_attempt_genotype_confirmed
        replace_status_stamps(mi,
          [
            [MiAttemptStatus.genotype_confirmed.description, '2011-11-12 00:00 UTC'],
            [MiAttemptStatus.micro_injection_in_progress.description, '2011-12-24 00:00 UTC'],
            [MiAttemptStatus.micro_injection_in_progress.description, '2011-06-12 00:00 UTC'],
            [MiAttemptStatus.genotype_confirmed.description, '2011-01-24 00:00 UTC']
          ]
        )
        assert_equal Date.parse('2011-06-12'), mi.in_progress_date
      end
    end

  end
end

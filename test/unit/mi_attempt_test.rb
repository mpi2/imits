# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create( :mi_attempt,
        :blast_strain             => Strain::BlastStrain.find_by_name('BALB/c'),
        :colony_background_strain => Strain::ColonyBackgroundStrain.find_by_name('129P2/OlaHsd'),
        :test_cross_strain        => Strain::TestCrossStrain.find_by_name('129P2/OlaHsd')
      )
    end

    context 'attribute tests:' do

      setup do
        default_mi_attempt
      end

      should 'have es_cell' do
        assert_should have_db_column(:es_cell_id).with_options(:null => false)
        assert_should belong_to(:es_cell)
      end

      context 'centres tests:' do
        should 'exist' do
          assert_should have_db_column(:distribution_centre_id)
          assert_should belong_to(:distribution_centre)
        end

        should 'not output private attributes in serialization' do
          assert_equal false, default_mi_attempt.as_json.include?('mi_plan_id')
          assert_equal false, default_mi_attempt.as_json.include?('production_centre_id')
          assert_equal false, default_mi_attempt.as_json.include?('distribution_centre_id')
        end

        should 'validate presence of production_centre_name' do
          assert_should validate_presence_of :production_centre_name
        end

        should 'default distribution_centre to production_centre' do
          centre  = Factory.create :centre
          mi_plan = Factory.create :mi_plan, :production_centre => centre
          mi      = Factory.create :mi_attempt, :mi_plan => mi_plan
          assert_equal centre.name, mi.distribution_centre.name
        end

        should 'not overwrite distribution_centre with production_centre if former has already been set' do
          centre1 = Factory.create :centre
          centre2 = Factory.create :centre
          mi_plan = Factory.create :mi_plan, :production_centre => centre1
          mi      = Factory.create :mi_attempt, :mi_plan => mi_plan, :distribution_centre => centre2
          assert_equal centre2.name, mi.distribution_centre.name
          assert_not_equal centre1.name, mi.distribution_centre.name
        end

        should 'allow access to distribution centre via its name' do
          centre = Factory.create :centre, :name => 'NONEXISTENT'
          default_mi_attempt.update_attributes(:distribution_centre_name => 'NONEXISTENT')
          assert_equal 'NONEXISTENT', default_mi_attempt.distribution_centre.name
        end

        should 'output *_centre_name fields in serialization' do
          mi_plan    = Factory.create(:mi_plan, :production_centre => Centre.find_by_name('WTSI'))
          mi_attempt = Factory.create(:mi_attempt, :mi_plan => mi_plan, :distribution_centre => Centre.find_by_name('ICS'))
          data       = JSON.parse(mi_attempt.to_json)
          assert_equal ['ICS', 'WTSI'], data.values_at('distribution_centre_name', 'production_centre_name')
        end
      end

      context '#mi_attempt_status' do
        should 'exist' do
          assert_should have_db_column(:mi_attempt_status_id).with_options(:null => false)
          assert_should belong_to(:mi_attempt_status)
        end

        should 'be set to "Micro-injection in progress" by default' do
          assert_equal 'Micro-injection in progress', default_mi_attempt.mi_attempt_status.description
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

        should 'not be mass-assignable by id' do
          default_mi_attempt.attributes = {
            :mi_attempt_status    => MiAttemptStatus.genotype_confirmed,
            :mi_attempt_status_id => MiAttemptStatus.genotype_confirmed
          }
          assert_not_equal MiAttemptStatus.genotype_confirmed, default_mi_attempt.mi_attempt_status
        end

        should 'not expose id to serialization' do
          data = JSON.parse(default_mi_attempt.to_json)
          assert_false data.has_key?('mi_attempt_status_id')
        end
      end

      context '#status virtual attribute' do
        should 'be the status string when read' do
          default_mi_attempt.mi_attempt_status = MiAttemptStatus.micro_injection_in_progress
          assert_equal 'Micro-injection in progress', default_mi_attempt.status
          default_mi_attempt.mi_attempt_status = MiAttemptStatus.genotype_confirmed
          assert_equal 'Genotype confirmed', default_mi_attempt.status
        end

        should 'be nil when actual status association is nil' do
          default_mi_attempt.mi_attempt_status = nil
          assert_nil default_mi_attempt.status
        end

        should 'be in serialization' do
          assert_equal default_mi_attempt.status, default_mi_attempt.as_json['status']
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

        should 'be nil if EsCell#allele_symbol_superscript_template is nil' do
          default_mi_attempt.es_cell.allele_symbol_superscript = nil
          assert_equal nil, default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'work if mouse_allele_type is present' do
          default_mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal 'tm2e(KOMP)Wtsi', default_mi_attempt.mouse_allele_symbol_superscript
        end

        should 'be output in serialization' do
          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal 'tm1e(EUCOMM)Wtsi', default_mi_attempt.as_json['mouse_allele_symbol_superscript']
        end
      end

      context '#mouse_allele_symbol' do
        setup do
          es_cell = Factory.create :es_cell_EPD0343_1_H06
          @mi_attempt = Factory.build :mi_attempt, :es_cell => es_cell
        end

        should 'be nil if mouse_allele_type is nil' do
          @mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          @mi_attempt.mouse_allele_type = nil
          assert_equal nil, @mi_attempt.mouse_allele_symbol
        end

        should 'work if mouse_allele_type is present' do
          @mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
          @mi_attempt.mouse_allele_type = 'e'
          assert_equal 'Myo1c<sup>tm2e(KOMP)Wtsi</sup>', @mi_attempt.mouse_allele_symbol
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
          default_mi_attempt.update_attributes(:blast_strain_name => 'Balb/Cam')
          assert_equal 'Balb/Cam', default_mi_attempt.blast_strain_name
        end

        should 'get and assign colony background strain via AccessAssociationByAttribute' do
          default_mi_attempt.update_attributes(:colony_background_strain_name => 'B6JTyr<c-Brd>')
          assert_equal 'B6JTyr<c-Brd>', default_mi_attempt.colony_background_strain_name
        end

        should 'get and assign test cross strain via AccessAssociationByAttribute' do
          default_mi_attempt.update_attributes(:test_cross_strain_name => 'C57BL/6NTacUSA')
          default_mi_attempt.reload
          assert_equal 'C57BL/6NTacUSA', default_mi_attempt.test_cross_strain_name
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

        should 'expose *_strain_name virtual methods to JSON API' do
          data = JSON.parse(default_mi_attempt.to_json)
          assert_equal ['BALB/c', '129P2/OlaHsd', '129P2/OlaHsd'],
                  data.values_at('blast_strain_name', 'colony_background_strain_name', 'test_cross_strain_name')
        end

        should 'not output strain IDs in serialized output' do
          data = JSON.parse(default_mi_attempt.to_json)
          assert ! data.has_key?('blast_strain_id')
          assert ! data.has_key?('colony_background_strain_id')
          assert ! data.has_key?('test_cross_strain_id')
        end

        should 'expose *_strain_name virtual methods to XML API' do
          doc = Nokogiri::XML(default_mi_attempt.to_xml)
          assert_equal ['BALB/c', '129P2/OlaHsd', '129P2/OlaHsd'],
                  [doc.css('blast-strain-name').text, doc.css('colony-background-strain-name').text, doc.css('test-cross-strain-name').text]
        end

        should 'allow setting blast strain to nil using blast_strain_name' do
          default_mi_attempt.update_attributes(:blast_strain_name => '')
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

        should 'be in serialized output' do
          default_mi_attempt.emma_status = 'suitable_sticky'
          data = JSON.parse(default_mi_attempt.to_json)
          assert_equal 'suitable_sticky', data['emma_status']
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

          should "output #{qc_field} in serialization" do
            assert default_mi_attempt.as_json.has_key? "#{qc_field}_result"
          end

          should 'default to "na" if assigned a blank' do
            default_mi_attempt.send("#{qc_field}_result=", '')
            assert default_mi_attempt.valid?
            assert_equal 'na', default_mi_attempt.send("#{qc_field}_result")
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
          default_mi_attempt.update_attributes(:colony_name => 'ABCD')
          assert_should have_db_index(:colony_name).unique(true)
          assert_should validate_uniqueness_of :colony_name
        end

        should 'be auto-generated if not supplied' do
          Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
          mi_plan = Factory.create(:mi_plan,
            :gene => EsCell.find_by_name!('EPD0127_4_E01').gene,
            :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
            :production_centre => Centre.find_by_name!('ICS')
          )
          attributes = {
            :mi_plan => mi_plan,
            :es_cell => EsCell.find_by_name!('EPD0127_4_E01'),
            :colony_name => nil
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

        should 'expose name in serialized output' do
          assert_equal default_mi_attempt.deposited_material_name, default_mi_attempt.as_json['deposited_material_name']
        end

        should 'not expose _id in serialization' do
          assert_false default_mi_attempt.as_json.has_key? 'deposited_material_id'
        end
      end

    end # attribute tests

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

    context 'for auditing' do
      should 'have updated_by column' do
        assert_should have_db_column(:updated_by_id).of_type(:integer)
      end

      should 'have updated_by association' do
        user = Factory.create :user
        subject.updated_by_id = user.id
        assert_equal user, subject.updated_by
      end
    end

    should 'have #comments' do
      mi = Factory.create :mi_attempt, :comments => 'this is a comment'
      assert_equal 'this is a comment', mi.comments
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

      should 'be output in JSON serialization' do
        assert_equal 'EPD0127_4_E01', JSON.parse(@mi_attempt.to_json)['es_cell_name']
      end

      should 'be output in XML serialization' do
        assert_equal 'EPD0127_4_E01', Nokogiri::XML(@mi_attempt.to_xml).css('es-cell-name').text
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
          assert_equal ['cannot be modified'], default_mi_attempt.errors['consortium_name']
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
          assert_equal ['cannot be modified'], default_mi_attempt.errors['production_centre_name']
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

    context '#mi_plan' do
      should 'have a production centre' do
        mi_plan = Factory.create(:mi_plan)
        assert_nil mi_plan.production_centre
        mi = Factory.build :mi_attempt, :mi_plan => mi_plan
        mi.valid?
        assert_equal ['must have a production centre (INTERNAL ERROR)'],
                mi.errors['mi_plan']
      end

      should 'on save be assigned to a matching MiPlan' do
        cbx1 = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1,
                :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')
        assert_equal 1, MiPlan.count

        mi_attempt = Factory.build :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => cbx1),
                :mi_plan => nil
        mi_attempt.production_centre_name = mi_plan.production_centre.name
        mi_attempt.consortium_name = mi_plan.consortium.name
        mi_attempt.save!

        assert_equal 1, MiPlan.count
        assert_equal mi_plan, mi_attempt.mi_plan
      end

      should 'on save, when assigning a matching MiPlan, set its status to Assigned if it is otherwise' do
        cbx1 = Factory.create :gene_cbx1
        mi_plan = Factory.create :mi_plan_with_production_centre, :gene => cbx1,
                :mi_plan_status => MiPlanStatus.find_by_name!('Interest')
        assert_equal 1, MiPlan.count

        mi_attempt = Factory.build :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => cbx1),
                :mi_plan => nil
        mi_attempt.production_centre_name = mi_plan.production_centre.name
        mi_attempt.consortium_name = mi_plan.consortium.name
        mi_attempt.save!

        assert_equal 1, MiPlan.count
        mi_plan.reload

        assert_equal mi_plan, mi_attempt.mi_plan
        assert_equal 'Assigned', mi_plan.mi_plan_status.name
      end

      should 'be created on save if none match gene, consortium and production centre' do
        cbx1 = Factory.create :gene_cbx1
        assert_equal 0, MiPlan.count

        mi_attempt = Factory.build :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => cbx1),
                :mi_plan => nil
        mi_attempt.production_centre_name = 'WTSI'
        mi_attempt.consortium_name = 'BaSH'
        mi_attempt.save!

        assert_equal 1, MiPlan.count
        assert_equal 'Cbx1', mi_attempt.mi_plan.gene.marker_symbol
        assert_equal 'WTSI', mi_attempt.mi_plan.production_centre.name
        assert_equal 'BaSH', mi_attempt.mi_plan.consortium.name
        assert_equal 'High', mi_attempt.mi_plan.mi_plan_priority.name
        assert_equal 'Assigned', mi_attempt.mi_plan.mi_plan_status.name
      end
    end

    context 'private attributes' do
      setup do
        @protected_attributes = [
          'created_at', 'updated_at', 'updated_by', 'updated_by_id',
          'es_cell', 'es_cell_id'
        ].sort
      end

      should 'be protected from mass assignment' do
        @protected_attributes.each do |attr|
          assert_include MiAttempt.protected_attributes, attr
        end
      end

      should 'not be output in json serialization' do
        data = JSON.parse(default_mi_attempt.to_json)
        values_in_both = @protected_attributes & data.keys
        assert_empty values_in_both
      end

      should 'not be output in xml serialization' do
        doc = Nokogiri::XML(default_mi_attempt.to_xml)
        assert_blank doc.css('qc-loxp-confirmation-id')
        assert_blank doc.css('created-at')
      end
    end

    should 'not output QC foreign keys in serialized output' do
      data = JSON.parse(default_mi_attempt.to_json)
      assert ! data.has_key?('qc_southern_blot_id')
    end

    should 'process default options in #as_json just like #to_json' do
      expected = JSON.parse(default_mi_attempt.to_json)
      got = default_mi_attempt.as_json.stringify_keys

      assert_equal expected, got, "diff: #{expected.diff(got)}"
    end

    context '::active' do
      should 'work' do
        10.times { Factory.create( :mi_attempt ) }
        10.times { Factory.create( :mi_attempt, :is_active => false ) }
        assert_equal MiAttempt.where(:is_active => true).count, MiAttempt.active.count
      end
    end

  end
end

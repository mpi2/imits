# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase
  context 'MiAttempt' do

    def default_mi_attempt
      @default_mi_attempt ||= Factory.create :mi_attempt,
              :blast_strain_id => Strain.find_by_name('Balb/C').id,
              :colony_background_strain_id => Strain.find_by_name('129P2/OlaHsd').id,
              :test_cross_strain_id => Strain.find_by_name('129P2/OlaHsd').id
    end

    context 'attribute tests' do

      setup do
        default_mi_attempt
      end

      should 'have clone' do
        assert_should have_db_column(:clone_id).with_options(:null => false)
        assert_should belong_to(:clone)
      end

      should 'have centres' do
        assert_should have_db_column(:production_centre_id).with_options(:null => false)
        assert_should belong_to(:production_centre)

        assert_should have_db_column(:distribution_centre_id)
        assert_should belong_to(:distribution_centre)
      end

      should 'validate presence of production_centre' do
        mi = MiAttempt.new
        mi.valid?
        assert_false mi.errors[:production_centre].blank?
      end

      should 'default distribution_centre to production_centre' do
        centre = Factory.create :centre
        mi = Factory.create :mi_attempt, :production_centre => centre
        assert_equal centre.name, mi.distribution_centre.name
      end

      should 'not overwrite distribution_centre with production_centre if former has already been set' do
        centre1 = Factory.create :centre
        centre2 = Factory.create :centre
        mi = Factory.create :mi_attempt, :production_centre => centre1, :distribution_centre => centre2
        assert_equal centre2.name, mi.distribution_centre.name
      end

      should 'have status' do
        assert_should have_db_column(:mi_attempt_status_id).with_options(:null => false)
        assert_should belong_to(:mi_attempt_status)
      end

      should 'set mi_attempt_status to "Micro-injection in progress" by default' do
        assert_equal 'Micro-injection in progress', default_mi_attempt.mi_attempt_status.description
      end

      should 'not overwrite status if it is set explicitly' do
        mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.genotype_confirmed)
        assert_equal 'Genotype confirmed', mi_attempt.mi_attempt_status.description
      end

      should 'not reset status to default if assigning id' do
        local_mi_attempt = Factory.create(:mi_attempt, :mi_attempt_status => MiAttemptStatus.genotype_confirmed)
        local_mi_attempt.mi_attempt_status_id = MiAttemptStatus.genotype_confirmed.id
        local_mi_attempt.save!
        local_mi_attempt = MiAttempt.find(local_mi_attempt.id)
        assert_equal 'Genotype confirmed', local_mi_attempt.mi_attempt_status.description
      end

      should 'have mouse allele type column' do
        assert_should have_db_column(:mouse_allele_type)
      end

      context '#mouse_allele_type' do
        should 'validate'
      end

      context '#mouse_allele_name_superscript' do
        should 'be nil if mouse_allele_type is nil' do
          default_mi_attempt.clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
          default_mi_attempt.mouse_allele_type = nil
          assert_equal nil, default_mi_attempt.mouse_allele_name_superscript
        end

        should 'be nil if Clone#allele_name_superscript_template is nil' do
          default_mi_attempt.clone.allele_name_superscript = nil
          assert_equal nil, default_mi_attempt.mouse_allele_name_superscript
        end

        should 'work if mouse_allele_type is present' do
          default_mi_attempt.clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
          default_mi_attempt.mouse_allele_type = 'e'
          assert_equal 'tm2e(KOMP)Wtsi', default_mi_attempt.mouse_allele_name_superscript
        end
      end

      context '#mouse_allele_name' do
        setup do
          clone = Factory.create :clone_EPD0343_1_H06
          @mi_attempt = Factory.build :mi_attempt, :clone => clone
        end

        should 'be nil if mouse_allele_type is nil' do
          @mi_attempt.clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
          @mi_attempt.mouse_allele_type = nil
          assert_equal nil, @mi_attempt.mouse_allele_name
        end

        should 'work if mouse_allele_type is present' do
          @mi_attempt.clone.allele_name_superscript = 'tm2b(KOMP)Wtsi'
          @mi_attempt.mouse_allele_type = 'e'
          assert_equal 'Myo1c<sup>tm2e(KOMP)Wtsi</sup>', @mi_attempt.mouse_allele_name
        end
      end

      context 'strain tests:' do
        should 'have a blast strain' do
          assert_equal Strain::BlastStrain, default_mi_attempt.blast_strain.class
          assert_equal 'Balb/C', default_mi_attempt.blast_strain.name
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
          assert_equal ['Balb/C', '129P2/OlaHsd', '129P2/OlaHsd'],
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
          assert_equal ['Balb/C', '129P2/OlaHsd', '129P2/OlaHsd'],
                  [doc.css('blast-strain-name').text, doc.css('colony-background-strain-name').text, doc.css('test-cross-strain-name').text]
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

      context '#emma_status' do
        should 'be :suitable if is_suitable_for_emma=true and is_emma_sticky=false' do
          default_mi_attempt.is_suitable_for_emma = true
          default_mi_attempt.is_emma_sticky = false
          assert_equal :suitable, default_mi_attempt.emma_status
        end

        should 'be :unsuitable if is_suitable_for_emma=false and is_emma_sticky=false' do
          default_mi_attempt.is_suitable_for_emma = false
          default_mi_attempt.is_emma_sticky = false
          assert_equal :unsuitable, default_mi_attempt.emma_status
        end

        should 'be :suitable_sticky if is_suitable_for_emma=true and is_emma_sticky=true' do
          default_mi_attempt.is_suitable_for_emma = true
          default_mi_attempt.is_emma_sticky = true
          assert_equal :suitable_sticky, default_mi_attempt.emma_status
        end

        should 'be :unsuitable_sticky if is_suitable_for_emma=false and is_emma_sticky=true' do
          default_mi_attempt.is_suitable_for_emma = false
          default_mi_attempt.is_emma_sticky = true
          assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
        end
      end

      context '#emma_status=' do
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

        should 'work for :suitable_sticky' do
          default_mi_attempt.emma_status = 'suitable_sticky'
          default_mi_attempt.save!
          default_mi_attempt.reload
          assert_equal [true, true], [default_mi_attempt.is_suitable_for_emma?, default_mi_attempt.is_emma_sticky?]
        end

        should 'work for :unsuitable_sticky' do
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
          assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
        end
      end

      context 'QC fields' do
        MiAttempt::QC_FIELDS.each do |qc_field|
          should "include #{qc_field}" do
            assert_should belong_to(qc_field)
          end
        end
      end

      should 'have should_export_to_mart' do
        assert_should have_db_column(:should_export_to_mart).of_type(:boolean).with_options(:default => true, :null => false)
      end

      should 'have is_active' do
        assert_should have_db_column(:is_active).of_type(:boolean).with_options(:default => true, :null => false)
      end

      should 'have is_released_from_genotyping' do
        assert_should have_db_column(:is_released_from_genotyping).of_type(:boolean).with_options(:default => false, :null => false)
      end

      context 'colony_name' do
        should 'be unique' do
          default_mi_attempt.update_attributes(:colony_name => 'ABCD')
          assert_should have_db_index(:colony_name).unique(true)
          assert_should validate_uniqueness_of :colony_name
        end

        should 'allow nils' do
          default_mi_attempt.update_attributes(:colony_name => nil)
          another_mi_attempt = Factory.build :mi_attempt, :colony_name => nil
          assert_nil another_mi_attempt.colony_name
          another_mi_attempt.valid?
          assert_blank another_mi_attempt.errors[:colony_name]
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
          default_mi_attempt.colony_name = ''
          default_mi_attempt.mouse_allele_type = ' '
          default_mi_attempt.is_active = false
          default_mi_attempt.save!
          default_mi_attempt.reload
          assert_equal 1, default_mi_attempt.total_male_chimeras
          assert_equal nil, default_mi_attempt.colony_name
          assert_equal nil, default_mi_attempt.mouse_allele_type
          assert_equal false, default_mi_attempt.is_active
        end
      end
    end

    context '::search scope' do

      setup do
        @clone1 = Factory.create :clone_EPD0343_1_H06
        @clone2 = Factory.create :clone_EPD0127_4_E01
        @clone3 = Factory.create :clone_EPD0029_1_G04
      end

      should 'return all results when not given any search terms' do
        results = MiAttempt.search(:search_terms => [])
        assert_equal 5, results.size
      end

      should 'return all results when only blank lines are in search terms' do
        results = MiAttempt.search(:search_terms => ["", "\t", "    "])
        assert_equal 5, results.size
      end

      should 'work for single clone' do
        results = MiAttempt.search(:search_terms => ['EPD0127_4_E01'])
        assert_equal 3, results.size
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
      end

      should 'work for single clone case-insensitively' do
        results = MiAttempt.search(:search_terms => ['epd0127_4_E01'])
        assert_equal 3, results.size
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
      end

      should 'work for multiple clones' do
        results = MiAttempt.search(:search_terms => ['EPD0127_4_E01', 'EPD0343_1_H06'])
        assert_equal 4, results.size
        assert_include results, @clone1.mi_attempts.first
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
        assert_not_include results, @clone3.mi_attempts.first
      end

      should 'work for single gene symbol' do
        results = MiAttempt.search(:search_terms => ['Myo1c'])
        assert_equal 1, results.size
        assert_include results, @clone1.mi_attempts.first
      end

      should 'work for single gene symbol case-insensitively' do
        results = MiAttempt.search(:search_terms => ['myo1C'])
        assert_equal 1, results.size
        assert_include results, @clone1.mi_attempts.first
      end

      should 'work for multiple gene symbols' do
        results = MiAttempt.search(:search_terms => ['Trafd1', 'Myo1c'])
        assert_equal 4, results.size
        assert_include results, @clone1.mi_attempts.first
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
        assert_not_include results, @clone3.mi_attempts.first
      end

      should 'work for single colony name' do
        results = MiAttempt.search(:search_terms => ['MBSS'])
        assert_equal 1, results.size
        @clone2.mi_attempts.each { |mi| assert_include results, mi if mi.colony_name == 'MBSS' }
        assert_not_include results, @clone3.mi_attempts.first
      end

      should 'work for single colony name case-insensitively' do
        results = MiAttempt.search(:search_terms => ['mbss'])
        assert_equal 1, results.size
        @clone2.mi_attempts.each { |mi| assert_include results, mi if mi.colony_name == 'MBSS' }
        assert_not_include results, @clone3.mi_attempts.first
      end

      should 'work for multiple colony names' do
        results = MiAttempt.search(:search_terms => ['MBSS', 'WBAA'])
        assert_equal 2, results.size
        @clone2.mi_attempts.find_all {|mi| !mi.colony_name.blank?}.each { |mi| assert_include results, mi }
        assert_not_include results, @clone3.mi_attempts.first
      end

      should 'work when mixing clone names, gene symbols and colony names' do
        results = MiAttempt.search(:search_terms => ['EPD0127_4_E01', 'Myo1c', 'MBFD'])
        assert_equal 5, results.size
        assert_include results, @clone1.mi_attempts.first
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
        assert_include results, @clone3.mi_attempts.first
      end

      should 'not have duplicates in results' do
        results = MiAttempt.search(:search_terms => ['EPD0127_4_E01', 'Trafd1'])
        assert_equal 3, results.size
        @clone2.mi_attempts.each { |mi| assert_include results, mi }
      end

      should 'be orderable' do
        results = MiAttempt.search(:search_terms => ['EPD0127_4_E01', 'Trafd1']).order('clones.clone_name DESC').all
      end

      should 'search by terms and filter by production centre' do
        mi = Factory.create(:mi_attempt, :clone => @clone1,
          :production_centre => Centre.find_by_name!('ICS'))
        results = MiAttempt.search(:search_terms => ['myo1c'],
          :production_centre_id => Centre.find_by_name!('ICS').id)
        assert_equal 1, results.size
        assert_equal mi.id, results.first.id
      end

      should 'filter by status' do
        mi1 = Factory.create(:mi_attempt, :clone => @clone1,
          :mi_attempt_status => MiAttemptStatus.genotype_confirmed)
        mi2 = Factory.create(:mi_attempt, :clone => @clone1,
          :mi_attempt_status => MiAttemptStatus.genotype_confirmed)

        results = MiAttempt.search(
          :mi_attempt_status_id => MiAttemptStatus.genotype_confirmed)
        assert_equal 2, results.size
        assert_include results, mi1
        assert_include results, mi2
      end

      should 'search by search term and filter by both production centre and status' do
        production_centre = Centre.find_by_name!('WTSI')
        status = MiAttemptStatus.create!(:description => 'Nonsense')

        mi = Factory.create(:mi_attempt, :clone => @clone2,
          :mi_attempt_status => status,
          :production_centre => production_centre)

        results = MiAttempt.search(:terms => [@clone2.marker_symbol],
          :mi_attempt_status_id => status.id,
          :production_centre_id => production_centre.id)
        assert_include results, mi
        assert_equal 1, results.size
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

    should 'have comments' do
      mi = Factory.create :mi_attempt, :comments => 'this is a comment'
      assert_equal 'this is a comment', mi.comments
    end

    context '#clone_name virtual attribute' do
      setup do
        Factory.create :clone_EPD0127_4_E01_without_mi_attempts
        Factory.create :clone_EPD0343_1_H06_without_mi_attempts

        @mi_attempt = mi = Factory.build(:mi_attempt)
        mi.clone_id = nil
        mi.clone = nil

        @mi_attempt.attributes = {:clone_name => 'EPD0127_4_E01'}
      end

      should 'be written on mass assignment' do
        assert_equal 'EPD0127_4_E01', @mi_attempt.clone_name
      end

      should 'be used to set the clone before save' do
        @mi_attempt.save!

        assert_equal 'EPD0127_4_E01', @mi_attempt.clone.clone_name
      end

      should 'be overridden by the associated clone\'s name if that exists' do
        @mi_attempt.clone = Clone.find_by_clone_name('EPD0343_1_H06')
        assert_equal 'EPD0343_1_H06', @mi_attempt.clone_name
      end

      should 'not be settable if there is an associated clone' do
        @mi_attempt.clone = Clone.find_by_clone_name('EPD0343_1_H06')
        @mi_attempt.clone_name = 'EPD0127_4_E01'
        assert_equal 'EPD0343_1_H06', @mi_attempt.clone_name
      end

      should 'pull in clone from marts if it is not in the DB' do
        @mi_attempt.clone_name = 'EPD0029_1_G04'
        @mi_attempt.save!

        assert_equal 'EPD0029_1_G04', @mi_attempt.clone_name
      end

      should 'validate as missing if not set and clone is not set either' do
        @mi_attempt.clone_name = nil
        @mi_attempt.valid?
        assert_equal ['cannot be blank'], @mi_attempt.errors['clone_name']
      end

      should 'not validate as missing if not set but clone is set' do
        @mi_attempt.clone_name = nil
        @mi_attempt.clone = Clone.find_by_clone_name('EPD0343_1_H06')
        @mi_attempt.valid?
        assert @mi_attempt.errors['clone_name'].blank?
      end

      should 'validate when clone_name is not a valid clone in the marts' do
        mi_attempt = MiAttempt.new(:clone_name => 'EPD0127_4_G01', :production_centre => Centre.first)
        assert_false mi_attempt.valid?
        assert ! mi_attempt.errors[:clone_name].blank?
      end

      should 'be output in JSON serialization' do
        assert_equal 'EPD0127_4_E01', JSON.parse(@mi_attempt.to_json)['clone_name']
      end

      should 'be output in XML serialization' do
        assert_equal 'EPD0127_4_E01', Nokogiri::XML(@mi_attempt.to_xml).css('clone-name').text
      end
    end

    context 'private attributes' do
      setup do
        @protected_attributes = [
          'type', 'created_at', 'updated_at', 'audit_ids', 'updated_by', 'updated_by_id',
          'clone_id', 'clone', 'mi_attempt_status', 'mi_attempt_status_id'
        ]
        @protected_attributes.sort!
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

    context 'virtual #qc attribute' do
      setup do
        @mi_attempt = Factory.build(:mi_attempt,
          :qc_southern_blot => QcResult.pass,
          :qc_five_prime_lr_pcr => QcResult.fail,
          :qc_five_prime_cassette_integrity => QcResult.na,
          :qc_tv_backbone_assay => nil,
          :qc_neo_count_qpcr => QcResult.na,
          :qc_neo_sr_pcr => QcResult.na,
          :qc_loa_qpcr => QcResult.na,
          :qc_homozygous_loa_sr_pcr => QcResult.na,
          :qc_lacz_sr_pcr => QcResult.na,
          :qc_mutant_specific_sr_pcr => QcResult.na,
          :qc_loxp_confirmation => QcResult.na,
          :qc_three_prime_lr_pcr => QcResult.na)
      end

      should ', when first accessed, get back existing qc result values' do
        assert_equal 'pass', @mi_attempt.qc['southern_blot']
        assert_equal 'fail', @mi_attempt.qc['five_prime_lr_pcr']
        assert_equal 'na', @mi_attempt.qc['five_prime_cassette_integrity']
        assert_equal nil, @mi_attempt.qc['tv_backbone_assay']
      end

      should ', when accessed after an assignment, contains assigned results with others' do
        @mi_attempt.qc = {
          'southern_blot' => 'fail',
          'five_prime_cassette_integrity' => nil,
          'neo_sr_pcr' => 'nonsense'
        }

        assert_equal 'fail', @mi_attempt.qc['southern_blot']
        assert_equal nil, @mi_attempt.qc['five_prime_cassette_integrity']
        assert_equal 'nonsense', @mi_attempt.qc['neo_sr_pcr']
        assert_equal 'na', @mi_attempt.qc['neo_count_qpcr']
      end

      context 'on save' do
        setup do
          @changed_qc_hash = {
            'southern_blot' => 'fail',
            'five_prime_lr_pcr' => 'pass',
            'five_prime_cassette_integrity' => nil,
            'tv_backbone_assay' => 'na'
          }.freeze
        end

        should 'write the fields that were specified with qc=' do
          @mi_attempt.qc = @changed_qc_hash.dup
          @mi_attempt.save!

          assert_equal QcResult.fail, @mi_attempt.qc_southern_blot
          assert_equal QcResult.pass, @mi_attempt.qc_five_prime_lr_pcr
          assert_equal           nil, @mi_attempt.qc_five_prime_cassette_integrity
          assert_equal   QcResult.na, @mi_attempt.qc_tv_backbone_assay
        end

        should 'not affect fields that were not specified with qc=' do
          @mi_attempt.qc = @changed_qc_hash.dup
          @mi_attempt.save!
          assert_equal QcResult.na, @mi_attempt.qc_neo_count_qpcr
        end

        should 'save fine without needing qc to be set first' do
          assert_nothing_raised do
            @mi_attempt.save!
          end
        end

        should 'ignore fields that are not actual QC fields' do
          @mi_attempt.qc = {'nonexistent' => 'nonsense'}
          assert_true @mi_attempt.save
          assert_false @mi_attempt.qc.keys.include? 'nonexistent'
        end

        should 'validate that the result string of each field is a valid result' do
          @mi_attempt.qc = {
            'southern_blot' => 'nonsense',
            'loxp_confirmation' => 'morenonsense'
          }

          assert_false @mi_attempt.valid?
          assert_match /southern_blot.+nonsense/, @mi_attempt.errors[:qc].first
          assert_match /loxp_confirmation.+morenonsense/, @mi_attempt.errors[:qc].first
        end
      end

      should 'be mass assignable' do
        @mi_attempt.update_attributes 'qc' => {'southern_blot' => 'fail'}

        assert_equal QcResult.fail, @mi_attempt.qc_southern_blot
      end

      should 'be output in to_xml output' do
        doc = Nokogiri::XML(@mi_attempt.to_xml)
        assert_equal 'pass', doc.css('qc > southern-blot').text
      end

      should 'be output in to_json output' do
        data = JSON.parse(@mi_attempt.to_json)

        assert_equal @mi_attempt.qc, data['qc']
      end

    end # virtual #qc attribute

    should 'not output QC foreign keys in serialized output' do
      data = JSON.parse(default_mi_attempt.to_json)
      assert ! data.has_key?('qc_southern_blot_id')
    end

    should 'process default options in #as_json just like #to_json' do
      assert_equal JSON.parse(default_mi_attempt.to_json), default_mi_attempt.as_json.stringify_keys
    end
  end
end

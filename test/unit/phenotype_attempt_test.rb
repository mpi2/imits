# encoding: utf-8

require 'test_helper'

class PhenotypeAttemptTest < ActiveSupport::TestCase
  context 'PhenotypeAttempt' do

    def default_phenotype_attempt
      @default_phenotype_attempt ||= Factory.create :phenotype_attempt, :colony_background_strain => Strain.find_by_name!('129P2/OlaHsd')
    end

    should 'be audited' do
      default_phenotype_attempt.is_active = false
      default_phenotype_attempt.save!
      assert ! Audit.where(:auditable_type => 'PhenotypeAttempt',
        :auditable_id => default_phenotype_attempt.id).blank?
    end

    should 'have #is_active' do
      assert_should have_db_column(:is_active).with_options(:null => false, :default => true)
    end

    context '#mi_attempt' do
      should 'work' do
        assert_should belong_to :mi_attempt
      end

      should 'be assignable to Genotype confirmed MiAttempt' do
        new_mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => default_phenotype_attempt.es_cell,
                :mi_plan => bash_wtsi_cbx1_plan(:gene => default_phenotype_attempt.gene, :force_assignment => true)
        default_phenotype_attempt.mi_attempt = new_mi
        default_phenotype_attempt.mi_plan.phenotype_only = true
        default_phenotype_attempt.save!
      end

      should 'not be set to MiAttempt that is not Genotype confirmed' do
        new_mi = Factory.create :mi_attempt2
        assert_equal MiAttempt::Status.micro_injection_in_progress, new_mi.status
        default_phenotype_attempt.mi_attempt = new_mi
        default_phenotype_attempt.valid?
        assert_match(/must be 'Genotype confirmed'/i, default_phenotype_attempt.errors['mi_attempt'].first)
      end
    end

    context '#mi_plan' do
      should 'not be overritten by default value if it is explicitly set' do
        mi_attempt = Factory.create :mi_attempt2_status_gtc
        plan = Factory.create :mi_plan_phenotype_only, :gene => mi_attempt.gene, :force_assignment => true
        pt = Factory.create :phenotype_attempt, :mi_attempt => mi_attempt, :mi_plan => plan
        assert_equal plan, pt.mi_plan
        assert_not_equal pt.mi_attempt.mi_plan, pt.mi_plan
      end

      should 'validate as having same gene as mi_attempt.es_cell' do
        plan = Factory.create :mi_plan_phenotype_only,
                :consortium => default_phenotype_attempt.mi_plan.consortium,
                :production_centre => default_phenotype_attempt.mi_plan.production_centre
        assert_not_equal plan.gene, default_phenotype_attempt.mi_attempt.es_cell.gene

        default_phenotype_attempt.mi_plan = plan
        assert ! default_phenotype_attempt.valid?
        assert_equal "mi_plan and es_cell gene mismatch!  Should be the same! (#{default_phenotype_attempt.mi_attempt.es_cell.gene.marker_symbol} != #{default_phenotype_attempt.mi_plan.gene.marker_symbol})", default_phenotype_attempt.errors[:base].first
      end

    end #mi_plan

    context '#status' do
      should 'work' do
        assert_should belong_to :status
      end
    end

    context '#rederivation_started' do
      should 'be in DB' do
        assert_should have_db_column(:rederivation_started).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.rederivation_started?
      end
    end

    context '#rederivation_complete' do
      should 'be in DB' do
        assert_should have_db_column(:rederivation_complete).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.rederivation_complete?
      end
    end

    context '#deleter_strain' do
      should 'be in DB' do
        assert_should have_db_column(:deleter_strain_id) #.with_options(:null => true)
        assert_should belong_to(:deleter_strain)
      end
    end

    context '#number_of_cre_matings_successful' do
      should 'be in DB' do
        assert_should have_db_column(:number_of_cre_matings_successful).with_options(:null => false)
      end

      should 'default to false' do
        assert_equal 0, default_phenotype_attempt.number_of_cre_matings_successful
      end
    end

    context '#phenotyping_started' do
      should 'be in DB' do
        assert_should have_db_column(:phenotyping_started).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.phenotyping_started?
      end
    end

    context '#phenotyping_complete' do
      should 'be in DB' do
        assert_should have_db_column(:phenotyping_complete).with_options(:null => false, :default => false)
      end

      should 'default to false' do
        assert_equal false, default_phenotype_attempt.phenotyping_complete?
      end
    end

    context '#status_stamps' do
      should 'be a valid association' do
        assert_should have_many :status_stamps
      end

      should 'be added when status changes' do
        assert_equal ['Phenotype Attempt Registered'], default_phenotype_attempt.status_stamps.map{|i| i.status.name}
        default_phenotype_attempt.rederivation_started = true
        default_phenotype_attempt.save!
        assert_equal ['Phenotype Attempt Registered', 'Rederivation Started'], default_phenotype_attempt.status_stamps.map{|i| i.status.name}
      end
    end

    context 'phenotyping_experiments_started' do
      should 'not be set if attempt has not started phenotyping' do
        pa =  Factory.create :phenotype_attempt_status_cec
        assert_equal pa.status_stamps.where('status_id = 7').count, 0
        assert_equal pa.phenotyping_experiments_started, nil
      end

      should 'default to phenotype_started date when blank' do
        pa =  Factory.create :phenotype_attempt_status_cec
        assert_equal pa.phenotyping_experiments_started, nil

        pa.phenotyping_started = true
        pa.save
        pa.reload
        assert_equal pa.phenotyping_experiments_started, pa.status_stamps.where('status_id = 7').first.created_at.to_date
      end

      should 'not be set to phenotype_started date when not blank' do
        pes_date = Time.now.to_date - 1.month
        pa =  Factory.create :phenotype_attempt_status_cec, :phenotyping_experiments_started => pes_date
        assert_not_nil pa.phenotyping_experiments_started

        pa.phenotyping_started = true
        pa.save
        pa.reload
        assert_not_equal pa.phenotyping_experiments_started, pa.status_stamps.where('status_id = 7').first.created_at.to_date
        assert_equal pa.phenotyping_experiments_started, pes_date
      end
    end

    context '#reportable_statuses_with_latest_dates' do
      should 'work' do
        default_phenotype_attempt.deleter_strain = DeleterStrain.first
        default_phenotype_attempt.save!
        default_phenotype_attempt.number_of_cre_matings_successful = 2
        default_phenotype_attempt.mouse_allele_type = 'b'
        default_phenotype_attempt.phenotyping_started = true
        default_phenotype_attempt.colony_background_strain = Strain.first
        default_phenotype_attempt.save!

        expected = {
          'Phenotype Attempt Registered' => Date.parse('2011-11-30'),
          'Cre Excision Started' => Date.parse('2011-12-01'),
          'Cre Excision Complete' => Date.parse('2011-12-02'),
          'Phenotyping Started' => Date.parse('2011-12-03')
        }

        replace_status_stamps(default_phenotype_attempt, expected)

        assert_equal expected, default_phenotype_attempt.reportable_statuses_with_latest_dates
      end
    end

    context '#colony_name' do
      should 'exist and be not null' do
        assert_should have_db_column(:colony_name).with_options(:limit => 125, :null => false)
      end

      should 'have unique index' do
        assert_should have_db_index(:colony_name).unique(true)
      end

      should 'be auto-generated' do
        mi = Factory.create :mi_attempt2_status_gtc, :colony_name => 'ABCD123'

        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        assert_equal 'ABCD123-1', pt.colony_name

        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        assert_equal 'ABCD123-2', pt.colony_name
      end

      should 'not be overwritten by auto-generation if set' do
        pt = Factory.create :phenotype_attempt, :colony_name => 'XYZ789'
        assert_equal 'XYZ789', pt.colony_name
      end

      should 'validate uniqueness insensitively' do
        default_phenotype_attempt.update_attributes!(:colony_name => 'ABCD')
        pa = Factory.build :phenotype_attempt, :colony_name => 'ABCD'; pa.valid?
        assert_match(/taken/, pa.errors[:colony_name].first)

        pa.colony_name = 'abcd'; pa.valid?
        assert_match(/taken/, pa.errors[:colony_name].first)
      end
    end

    context '#gene' do
      should 'be the mi_plan\'s gene if it is set' do
        plan = Factory.create :mi_plan_with_production_centre
        mi = Factory.create :mi_attempt2
        pa = Factory.build :phenotype_attempt, :mi_plan => plan, :mi_attempt => mi
        assert_equal plan.gene, pa.gene
      end

      should 'be the #mi_attempt\'s gene if it is set but there is no mi_plan' do
        mi = Factory.create :mi_attempt2
        pa = Factory.build :phenotype_attempt, :mi_plan => nil, :mi_attempt => mi
        assert_equal mi.gene, pa.gene
      end

      should 'be nil if neither are set' do
        pa = Factory.build :phenotype_attempt, :mi_plan => nil, :mi_attempt => nil
        assert_equal nil, pa.gene
      end
    end

    context '#es_cell' do
      should 'be the mi_attempt\'s es_cell' do
        assert_equal default_phenotype_attempt.mi_attempt.es_cell,
                default_phenotype_attempt.es_cell
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
        default_phenotype_attempt.mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        default_phenotype_attempt.mouse_allele_type = nil
        assert_equal nil, default_phenotype_attempt.mi_attempt.mouse_allele_symbol_superscript
      end

      should 'be nil if TargRep::EsCell#allele_symbol_superscript_template and mouse_allele_type are nil' do
        default_phenotype_attempt.mi_attempt.es_cell.allele_symbol_superscript = nil
        assert_equal nil, default_phenotype_attempt.mouse_allele_symbol_superscript
      end

      should 'be nil if TargRep::EsCell#allele_symbol_superscript_template is nil and mouse_allele_type is not nil' do
        es_cell = default_phenotype_attempt.mi_attempt.es_cell
        es_cell.allele_symbol_superscript = nil
        es_cell.save
        default_phenotype_attempt.mouse_allele_type = 'e'
        assert_equal nil, default_phenotype_attempt.mi_attempt.mouse_allele_symbol_superscript
      end

      should 'work if mouse_allele_type is present' do
        es_cell = default_phenotype_attempt.mi_attempt.es_cell
        es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        es_cell.save!
        default_phenotype_attempt.mouse_allele_type = 'e'
        assert_equal 'tm2e(KOMP)Wtsi', default_phenotype_attempt.mouse_allele_symbol_superscript
      end
    end

    context '#mouse_allele_symbol' do
      setup do
        @es_cell = Factory.create :es_cell_EPD0343_1_H06, :allele => Factory.create(:allele_with_gene_myolc)
        @mi_attempt = Factory.create :mi_attempt2_status_gtc, :es_cell => @es_cell,
          :mi_plan => Factory.create(:mi_plan_with_production_centre, :gene => @es_cell.gene, :force_assignment => true)
        @es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
        @es_cell.save!
        @phenotype_attempt = Factory.create :phenotype_attempt, :mi_attempt => @mi_attempt
      end

      should 'be nil if mouse_allele_type is nil' do
        @phenotype_attempt.mouse_allele_type = nil
        assert_equal nil, @phenotype_attempt.mouse_allele_symbol
      end

      should 'work if mouse_allele_type is present' do
        @phenotype_attempt.mouse_allele_type = 'e'
        assert_equal 'Myo1c<sup>tm2e(KOMP)Wtsi</sup>', @phenotype_attempt.mouse_allele_symbol
      end

      should 'be nil if es_cell.allele_symbol_superscript is nil, even if mouse_allele_type is set' do
        @es_cell.allele_symbol_superscript = nil
        @es_cell.save!
        @phenotype_attempt.mi_attempt.es_cell.reload
        @phenotype_attempt.mouse_allele_type = 'e'
        assert_nil @phenotype_attempt.mouse_allele_symbol
      end
    end

    context '#allele_symbol' do
      setup do
        @es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts, :allele => Factory.create(:allele_with_gene_trafd1)
      end

      should 'return the mouse_allele_symbol if mouse_allele_type is at or after Cre Excision Complete' do
        pt = Factory.create :phenotype_attempt_status_pdc
        pt.mi_attempt.stubs(:allele_symbol => 'MI ATTEMPT ALLELE SYMBOL')

        assert_equal pt.mouse_allele_symbol, pt.allele_symbol
      end

      should 'return the mi attempt\'s allele_symbol if mouse_allele_type is not set' do
        pt = Factory.create :phenotype_attempt, :mouse_allele_type => 'b'
        pt.mi_attempt.stubs(:allele_symbol => 'MI ATTEMPT ALLELE SYMBOL')

        assert_equal 'MI ATTEMPT ALLELE SYMBOL', pt.allele_symbol
      end
    end

    context '#consortium' do
      should 'delegate to mi_plan' do
        assert_equal default_phenotype_attempt.consortium, default_phenotype_attempt.mi_plan.consortium
      end
    end

    context '#production_centre' do
      should 'delegate to mi_plan' do
        assert_equal default_phenotype_attempt.production_centre, default_phenotype_attempt.mi_plan.production_centre
      end
    end

    context '#distribution_centres' do
      should 'exist' do
        assert_should have_many(:distribution_centres)
      end

      #should 'have 1 created by default if it goes past the Cre Excision Complete status' do
      #  pa = Factory.create :phenotype_attempt
      #  assert_equal 0, pa.distribution_centres.count

      #  pa = Factory.create :phenotype_attempt_status_pdc
      #  assert_equal 1, pa.distribution_centres.count
      #  dc = pa.distribution_centres.first
      #  assert_equal 'Frozen embryos', dc.deposited_material.name
      #  assert_equal pa.production_centre.name, dc.centre.name
      #end

      #should 'test that if a status is changed, distribution centre creation logic is triggered on the new value, not the old value' do
      #  pa = Factory.create :phenotype_attempt_status_pdc
      #  dc = PhenotypeAttempt::DistributionCentre.find_all_by_phenotype_attempt_id(pa.id)
      #  dc.first.destroy

      #  pa.number_of_cre_matings_successful = 0
      #  pa.phenotyping_started = false
      #  pa.phenotyping_complete = false
      #  pa.save!
      #  pa.reload
      #  pa.distribution_centres.reload
      #  assert_equal 0, pa.distribution_centres.count
      #end

      #should 'be refreshed when a one is created automatically' do
      #  pa = Factory.create :phenotype_attempt
      #  assert_equal [], pa.distribution_centres.all
      #  pa.deleter_strain = DeleterStrain.first
      #  pa.colony_background_strain = Strain.first
      #  pa.number_of_cre_matings_successful = 1
      #  pa.mouse_allele_type = 'b'
      #  pa.save!
      #  assert_kind_of PhenotypeAttempt::DistributionCentre, pa.distribution_centres.first
      #end
    end

    context 'before filter' do
      context '#set_blank_strings_to_nil (before validation)' do
        should 'work' do
          default_phenotype_attempt.mouse_allele_type = ' '
          default_phenotype_attempt.valid?
          assert_equal nil, default_phenotype_attempt.mouse_allele_type
        end
      end
    end

    context '#distribution_centres_formatted_display' do
      should 'output a string of distribution centre and deposited material' do
        pa = Factory.create :phenotype_attempt_status_pdc,
                :mi_attempt => Factory.create(:mi_attempt2_status_gtc, :mi_plan => bash_wtsi_cbx1_plan)

        dc = Factory.create(:phenotype_attempt_distribution_centre, :centre => pa.production_centre, :phenotype_attempt => pa, :deposited_material => DepositedMaterial.find_by_name!('Frozen embryos'))
        assert_equal "[WTSI, Frozen embryos]", pa.distribution_centres_formatted_display
      end
    end

    context '#colony_background_strain' do
      should 'have correct definition' do
        assert_should belong_to(:colony_background_strain)
        assert_should have_db_column(:colony_background_strain_id)
      end

      should 'just work' do
        pa = Factory.create :phenotype_attempt_status_pdc

        assert_true pa.valid?
        assert_true pa.save!

        pa.reload
        assert_equal pa.colony_background_strain, Strain.first
      end

      should 'have a colony background strain mgi accession id' do
        assert_equal 'MGI:28', default_phenotype_attempt.colony_background_strain_mgi_accession
      end

      should 'have a colony background strain mgi name' do
        assert_equal '129P2/OlaHsd', default_phenotype_attempt.colony_background_strain_mgi_name
      end

      should 'expect colony_background_strain when cre excision is complete' do
        pa = Factory.create :phenotype_attempt

        pa.number_of_cre_matings_successful = 10
        pa.deleter_strain = DeleterStrain.first
        pa.mouse_allele_type = 'b'
        pa.rederivation_started = true
        pa.rederivation_complete = true

        assert_true pa.valid?
        assert_equal 'Cre Excision Started', pa.status.name

        pa.colony_background_strain = Strain.first
        assert_true pa.valid?
        assert_equal 'Cre Excision Complete', pa.status.name
      end
    end

    should 'include HasStatuses' do
      assert_include default_phenotype_attempt.class.ancestors, ApplicationModel::HasStatuses
    end

    should 'have #allele_id' do
      assert_equal default_phenotype_attempt.mi_attempt.allele_id,
              default_phenotype_attempt.allele_id
    end

    should 'have ::readable_name' do
      assert_equal 'phenotype attempt', PhenotypeAttempt.readable_name
    end

    should 'handle template character in allele_symbol_superscript_template' do
      phenotype_attempt = Factory.create :phenotype_attempt

      phenotype_attempt.rederivation_started = true
      phenotype_attempt.rederivation_complete = true
      phenotype_attempt.number_of_cre_matings_started = 1
      phenotype_attempt.number_of_cre_matings_successful = 1
      phenotype_attempt.deleter_strain = DeleterStrain.all.first
      phenotype_attempt.colony_background_strain = Strain.all.first
      phenotype_attempt.mouse_allele_type = '.1'
      phenotype_attempt.save!
      assert_equal "Cre Excision Complete", phenotype_attempt.status.name

      assert_match(/Auto\-generated Symbol \d+<sup>tm1.1\(EUCOMM\)Wtsi<\/sup>/, phenotype_attempt.allele_symbol)

      old_allele_symbol_superscript_template = phenotype_attempt.es_cell.allele_symbol_superscript_template
      phenotype_attempt.es_cell.allele_symbol_superscript_template = phenotype_attempt.es_cell.allele_symbol_superscript_template.gsub(/@/, '')

      phenotype_attempt.es_cell.save!

      assert_match(/Auto-generated Symbol \d+<sup>tm1\(EUCOMM\)Wtsi<\/sup>/, phenotype_attempt.allele_symbol)

      assert phenotype_attempt.es_cell.allele_symbol_superscript_template !~ /@/
      assert phenotype_attempt.allele_symbol !~ /@/
    end


    should 'include BelongsToMiPlan' do
      assert_include PhenotypeAttempt.ancestors, ApplicationModel::BelongsToMiPlan
    end

  end
end

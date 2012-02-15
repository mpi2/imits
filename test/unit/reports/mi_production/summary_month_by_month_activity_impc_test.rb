# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityImpcTest < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivityImpc' do

    def generate
      @generated ||= Reports::MiProduction::SummaryMonthByMonthActivityImpc.generate
    end

    should 'ensure all consortia are included' do
      plan1 = TestDummy.mi_plan('Monterotondo', 'Monterotondo')
      plan1.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan1,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      plan2 = TestDummy.mi_plan('Monterotondo', 'Monterotondo')
      plan2.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan2,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      csv = CSV.parse(generate[:csv])
      assert_equal Consortium.all.size + 1, csv.size, csv.inspect
    end

    should 'report for each month August 2011 and forward' do
      mi = Factory.create :wtsi_mi_attempt_genotype_confirmed, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      plan = mi.mi_plan
      plan.update_attributes!(:number_of_es_cells_starting_qc => 1)
      pt = Factory.create :phenotype_attempt, :mi_plan => plan, :mi_attempt => mi

      replace_status_stamps(plan,
        'Assigned' => '2011-01-01',
        'Assigned - ES Cell QC In Progress' => '2011-07-31')
      replace_status_stamps(mi,
        'Micro-injection in progress' => '2011-07-31',
        'Genotype confirmed' => '2011-07-31')
      replace_status_stamps(pt,
        'Phenotype Attempt Registered' => '2011-07-31')

      puts generate[:table].to_s if DEBUG

      csv = CSV.parse(generate[:csv])
      assert_equal plan, mi.mi_plan
      assert_equal plan, pt.mi_plan
      assert_equal 1, csv.size, csv.inspect
    end

    should 'accumulate numbers for Plans' do
      plan1 = TestDummy.mi_plan('BaSH', 'WTSI')
      plan1.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan1,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      plan2 = TestDummy.mi_plan('BaSH', 'WTSI')
      plan2.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan2,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      puts generate[:table].to_s if DEBUG

      csv = CSV.parse(generate[:csv])
      assert_equal Consortium.all.size + 1, csv.size, csv.inspect
      assert_equal ['2011','8', 'BaSH', '2', '0', '0', 'WTSI'], csv[3][0..6]

    end

  should 'accumulate numbers for MiAttempts for distinct genes'
  should 'accumulate numbers of PhenotypeAttempts for distinct genes'
  should 'ensure all komp2 consortia are listed'

  end
end

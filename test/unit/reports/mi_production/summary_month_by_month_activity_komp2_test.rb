# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Test< ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivityKomp2' do

    def generate
      @generated ||= Reports::MiProduction::SummaryMonthByMonthActivityKomp2.generate
    end

    should 'ensure non KOMP2 consortia are ignored' do
      plan1 = TestDummy.mi_plan('Monterotondo', 'Monterotondo')
      plan1.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan1,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      plan2 = TestDummy.mi_plan('Monterotondo', 'Monterotondo')
      plan2.update_attributes!(:number_of_es_cells_starting_qc => 1)
      replace_status_stamps(plan2,
        'Assigned - ES Cell QC In Progress' => '2011-08-01')

      csv = CSV.parse(generate[:csv])
      assert_equal 1, csv.size, csv.inspect
    end

    should 'report for each month June 2011 and forward' do
      mi = Factory.create :wtsi_mi_attempt_genotype_confirmed, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      plan = mi.mi_plan
      plan.update_attributes!(:number_of_es_cells_starting_qc => 1)
      pt = Factory.create :phenotype_attempt, :mi_plan => plan, :mi_attempt => mi

      replace_status_stamps(plan,
        'Assigned' => '2011-01-01',
        'Assigned - ES Cell QC In Progress' => '2011-05-31')
      replace_status_stamps(mi,
        'Micro-injection in progress' => '2011-05-31',
        'Genotype confirmed' => '2011-05-31')
      replace_status_stamps(pt,
        'Phenotype Attempt Registered' => '2011-05-31')

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

      expected = [
        ["2011", "8", "BaSH", "2", "0", "0", "WTSI"],
        ["2011", "8", "DTCC", "0", "0", "0", ""],
        ["2011", "8", "JAX", "0", "0", "0", ""]
      ]

      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..6]}
      assert_equal expected, got
    end

    should 'accumulate numbers for MiAttempts for distinct genes' do
      2.times do
        es_cell = Factory.create :es_cell
        mi = Factory.create :mi_attempt, :es_cell => es_cell,
                :consortium_name => 'BaSH', :production_centre_name => 'WTSI'
        replace_status_stamps(mi.mi_plan, 'Assigned' => '2011-01-01')
        replace_status_stamps(mi, 'Micro-injection in progress' => '2011-08-01')
        mi = Factory.create :mi_attempt, :es_cell => es_cell,
                :consortium_name => 'BaSH', :production_centre_name => 'WTSI'
        replace_status_stamps(mi.mi_plan, 'Assigned' => '2011-01-01')
        replace_status_stamps(mi, 'Micro-injection in progress' => '2011-08-01')
      end

      puts generate[:table].to_s if DEBUG

      expected = [
        ["2011", "8", "BaSH", "0", "0", "0", "WTSI", "2"],
        ["2011", "8", "DTCC", "0", "0", "0", "", "0"],
        ["2011", "8", "JAX", "0", "0", "0", "", "0"]
      ]

      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..7]}
      assert_equal expected, got
    end

    should 'accumulate numbers of PhenotypeAttempts for distinct genes' do
      2.times do
        mi = Factory.create :wtsi_mi_attempt_genotype_confirmed, :consortium_name => 'BaSH', :production_centre_name => 'WTSI'
        replace_status_stamps(mi.mi_plan,
          'Assigned' => '2011-01-01'
        )
        replace_status_stamps(mi,
          'Micro-injection in progress' => '2011-01-01',
          'Genotype confirmed' => '2011-02-01')
        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        replace_status_stamps(pt, 'Phenotype Attempt Registered' => '2011-08-01')
        pt = Factory.create :phenotype_attempt, :mi_attempt => mi
        replace_status_stamps(pt, 'Phenotype Attempt Registered' => '2011-08-01')
      end

      expected = [
        ["2011", "8", "BaSH", "0", "0", "0", "WTSI", "0", "0", "0", "2", "0"],
        ["2011", "8", "DTCC", "0", "0", "0", "", "0", "0", "0", "0", "0"],
        ["2011", "8", "JAX", "0", "0", "0", "", "0", "0", "0", "0", "0"]
      ]

      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..11]}
      assert_equal expected, got
    end

    should 'ensure some plan statuses are ignored' do
      # TODO Replace this with TestDummy.gene_line eventually, so it sets the
      # MiPlan to the correct status rather than just setting the status stamp
      array = [
        'Interest',
        'Conflict',
        'Inspect - GLT Mouse',
        'Inspect - MI Attempt',
        'Inspect - Conflict',
        'Assigned',
        'Inactive',
        'Withdrawn'
      ]

      array.each do |status|
        plan = TestDummy.mi_plan('BaSH', 'WTSI')
        replace_status_stamps(plan,
          status => '2011-08-01')
      end

      expected = [
        ["2011", "8", "BaSH", "0", "0", "0"],
        ["2011", "8", "DTCC", "0", "0", "0"],
        ["2011", "8", "JAX", "0", "0", "0"]
      ]
      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..5]}
      assert_equal expected, got
    end

    should 'ensure all komp2 consortia are listed' do
      plan1 = TestDummy.mi_plan('BaSH', 'WTSI')
      plan1.update_attributes!(:number_of_es_cells_starting_qc => 1)

      puts generate[:table].to_s if DEBUG

      csv = CSV.parse(generate[:csv])
      assert_equal 4, csv.size, csv.inspect
    end

    should 'not accumulate previous MiPlan statuses' do
      2.times do
        p = TestDummy.mi_plan('BaSH', 'WTSI')
        p.update_attributes!(:number_of_es_cells_starting_qc => 1)
        replace_status_stamps(p,
          'Interest' => '2011-01-01',
          'Assigned - ES Cell QC In Progress' => '2011-06-01'
        )
      end
      p = TestDummy.mi_plan('BaSH', 'WTSI')
      p.update_attributes!(:number_of_es_cells_passing_qc => 1)
      replace_status_stamps(p,
        'Interest' => '2011-01-01',
        'Assigned - ES Cell QC In Progress' => '2011-05-01',
        'Assigned - ES Cell QC Complete' => '2011-06-10'
      )

      expected = [
        ["2011", "6", "BaSH", "2", "1", "0"],
        ["2011", "6", "DTCC", "0", "0", "0"],
        ["2011", "6", "JAX", "0", "0", "0"]
      ]

      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..5]}
      assert_equal expected, got
    end

    should 'not accumulate previous MiAttempt statuses' do
      mi1 = Factory.create :mi_attempt, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      replace_status_stamps(mi1.mi_plan,
        'Assigned' => '2011-01-01'
      )
      replace_status_stamps(mi1,
        'Micro-injection in progress' => '2011-08-01'
      )

      mi2 = Factory.create :wtsi_mi_attempt_genotype_confirmed, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      replace_status_stamps(mi2.mi_plan,
        'Assigned' => '2011-01-01'
      )
      replace_status_stamps(mi2,
        'Micro-injection in progress' => '2011-01-01',
        'Genotype confirmed' => '2011-08-01'
      )

      expected = [
        ['2011', '8', 'BaSH', '0', '0', '0', 'WTSI', '1', '1'],
        ['2011', '8', 'DTCC', '0', '0', '0', '', '0', '0'],
        ['2011', '8', 'JAX', '0', '0', '0', '', '0', '0']
      ]

      csv = CSV.parse(generate[:csv])
      got = csv[1..-1].map {|r| r[0..8]}
      assert_equal expected, got
    end
  end

end

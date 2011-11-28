# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::DetailTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::Detail' do
    setup do
      cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan,
        :consortium => Consortium.find_by_name!('BaSH'),
        :production_centre => Centre.find_by_name!('ICS'),
        :gene => cbx1
      Factory.create :mi_plan,
        :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
        :production_centre => Centre.find_by_name!('WTSI')

      bash_wtsi_attempt = Factory.create(:mi_attempt,
        :es_cell => Factory.create(:es_cell, :gene => cbx1),
        :consortium_name => 'BaSH',
        :production_centre_name => 'WTSI')
      bash_wtsi_plan = bash_wtsi_attempt.mi_plan
      stamp = bash_wtsi_plan.status_stamps.where(:mi_plan_status_id => MiPlanStatus['Assigned'].id).first
      stamp.created_at = Time.parse('2011-11-02 23:59:59.999 UTC')
      stamp.save!

      @report = Reports::MiProduction::Detail.generate
    end

    should 'have columns in correct order' do
      expected = [
        'Consortium',
        'Production Centre',
        'Gene',
        'Assigned Date',
        'ES Cells QC Complete date',
        'Micro-injection in progress date',
        'Genotype confirmed date',
        'Micro-injection Aborted date'
      ]

      assert_equal expected, @report.column_names
    end

    should 'have correct values where all columns are filled in' do
      bash_wtsi_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'WTSI'}
      expected = {
        'Consortium' => 'BaSH',
        'Production Centre' => 'WTSI',
        'Gene' => 'Cbx1',
        'Assigned Date' => '2011-11-02'
      }
      assert_equal expected, bash_wtsi_row.data
    end

    should 'have correct values where all optional columns are empty' do
      bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
      expected = {
        'Consortium' => 'BaSH',
        'Production Centre' => 'ICS',
        'Gene' => 'Cbx1',
        'Assigned Date' => nil
      }
      assert_equal expected, bash_ics_row.data
    end
  end

end

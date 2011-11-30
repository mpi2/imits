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
      bash_wtsi_plan.status_stamps.create!(:mi_plan_status => MiPlanStatus['Assigned'],
        :created_at => '2011-11-01 00:00:00 UTC')
      bash_wtsi_plan.status_stamps.create!(:mi_plan_status => MiPlanStatus['Interest'],
        :created_at => '2011-10-25 00:00:00 UTC')
      bash_wtsi_plan.status_stamps.create!(:mi_plan_status => MiPlanStatus['Assigned - ES Cell QC Complete'],
        :created_at => '2011-11-20 00:00:00 UTC')

      @report = Reports::MiProduction::Detail.generate
    end

    should 'have columns in correct order' do
      expected = [
        'Consortium',
        'Production Centre',
        'Gene',
        'Assigned Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Genotype confirmed Date',
        'Micro-injection Aborted Date'
      ]

      assert_equal expected, @report.column_names
    end

    should 'have correct values where all columns are filled in' do
      bash_wtsi_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'WTSI'}
      expected = {
        'Consortium' => 'BaSH',
        'Production Centre' => 'WTSI',
        'Gene' => 'Cbx1',
        'Assigned Date' => '2011-11-02',
        'Assigned - ES Cell QC Complete Date' => '2011-11-20'
      }
      assert_equal expected, bash_wtsi_row.data
    end

    should 'have correct values where optional columns are empty' do
      bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
      [
        'Assigned',
        'Assigned - ES Cells QC Complete Date',
        'Micro-injection in progress Date',
        'Genotype confirmed Date',
        'Micro-injection Aborted Date'
      ].each do |column_name|
        assert_nil bash_ics_row.data[column_name], "#{column_name} should be blank"
      end
    end

    should 'not have columns for statuses that are not wanted in the report' do
      bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
      assert_equal false, bash_ics_row.data.include?('Interest Date')
    end
  end

end

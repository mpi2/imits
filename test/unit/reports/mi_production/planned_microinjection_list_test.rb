# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PlannedMicroinjectionListTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::PlannedMicroinjectionList' do
    should 'create BaSH report' do

      bash_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'), :status => MiPlan::Status['Assigned']

      report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'

      line1 = report.to_csv.lines.first

      assert_match "Consortium,<supress>SubProject</supress>,Bespoke,Production Centre,Marker Symbol,MGI Accession ID,Priority,Status,Reason for Inspect/Conflict,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", line1

    end
  end

end

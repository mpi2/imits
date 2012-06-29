# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PlannedMicroinjectionListTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::PlannedMicroinjectionList' do
    should 'create BaSH report' do

      bash_plan = Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'), :status => MiPlan::Status['Assigned']

      report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'

      array = report.to_csv.lines.first 2

      assert_match "Consortium,SubProject,Bespoke,Production Centre,Marker Symbol,MGI Accession ID,Priority,Status,Reason for Inspect/Conflict,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", array[0]
      assert_match 'BaSH,"",No,,Auto-generated Symbol 1,MGI:0000000001,High,Assigned,,,[BaSH],,,', array[1]

    end
  end

end

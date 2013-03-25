# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PlannedMicroinjectionListTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::PlannedMicroinjectionList' do
    should 'create BaSH report' do
      Factory.create :mi_plan,
              :consortium        => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('ICS')
      Reports::MiProduction::Intermediate.new.cache

      report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'

      line1 = report.to_csv.lines.first

      assert_match "Consortium,SubProject,Bespoke,Recovery,Completion note,Phenotype only?,Production Centre,Marker Symbol,MGI Accession ID,Priority,Plan Status,Latest plan status date,Best Status,Reason for Inspect/Conflict,# Aborted attempts on this plan,Date of latest aborted attempt,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", line1

    end
  end

end

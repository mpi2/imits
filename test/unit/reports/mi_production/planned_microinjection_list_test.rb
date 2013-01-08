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

      assert_match "Consortium,SubProject,Bespoke,Phenotype only?,Production Centre,Marker Symbol,MGI Accession ID,Priority,Plan Status,Best Status,Reason for Inspect/Conflict,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", line1

    end
  end

end

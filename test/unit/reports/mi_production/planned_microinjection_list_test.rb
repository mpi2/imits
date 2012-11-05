# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PlannedMicroinjectionListTest < ActiveSupport::TestCase

  setup do
    cbx1 = Factory.create :gene_cbx1

    Factory.create :mi_plan,
            :consortium        => Consortium.find_by_name!('BaSH'),
            :production_centre => Centre.find_by_name!('ICS'),
            :gene              => cbx1

    es_cell = Factory.create(:es_cell,
      :name                      => 'EPD0027_2_A01',
      :gene                      => cbx1,
      :mutation_subtype          => 'conditional_ready',
      :ikmc_project_id           => 35505,
      :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'
    )

    bash_wtsi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
            :es_cell                  => es_cell,
            :consortium_name          => 'BaSH',
            :production_centre_name   => 'WTSI',
            :mouse_allele_type        => 'c',
            :colony_background_strain => Strain.find_by_name!('C57BL/6N')

    replace_status_stamps(bash_wtsi_attempt,
      'Micro-injection in progress' => '2011-11-22 00:00:00 UTC',
      'Chimeras obtained'           => '2011-11-22 23:59:59 UTC',
      'Genotype confirmed'          => '2011-11-23 00:00:00 UTC'
    )

    Reports::MiProduction::Intermediate.new.cache
  end

  context 'Reports::MiProduction::PlannedMicroinjectionList' do
    should 'create BaSH report' do

      report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'

      line1 = report.to_csv.lines.first

      assert_match "Consortium,SubProject,Bespoke,Production Centre,Marker Symbol,MGI Accession ID,Priority,Plan Status,Best Status,Reason for Inspect/Conflict,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", line1

    end
  end

end

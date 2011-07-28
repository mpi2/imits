# encoding: utf-8

require 'test_helper'

module Cron
  class BackFillMgiAccessionIdsInEsCellsScriptTest < ExternalScriptTestCase
    context './script/back_fill_mgi_accession_ids_in_es_cells.rb' do

      should 'work' do
        es_cell_1a = Factory.create :es_cell, :marker_symbol => 'Cbx1', :mgi_accession_id => nil
        es_cell_1b = Factory.create :es_cell, :marker_symbol => 'Cbx1', :mgi_accession_id => nil
        es_cell_2 = Factory.create :es_cell, :marker_symbol => 'Cbx2', :mgi_accession_id => 'MGI:FAKE_CBX2_001'
        es_cell_3 = Factory.create :es_cell, :marker_symbol => 'Trafd1', :mgi_accession_id => nil
        es_cell_4 = Factory.create :es_cell, :marker_symbol => 'Nonsense1', :mgi_accession_id => nil

        output = run_script './script/runner lib/migration/back_fill_mgi_accession_ids_in_es_cells.rb'
        puts output

        es_cell_1a.reload
        es_cell_1b.reload
        es_cell_2.reload
        es_cell_3.reload
        es_cell_4.reload

        assert_equal 'MGI:105369', es_cell_1a.mgi_accession_id
        assert_equal 'MGI:105369', es_cell_1b.mgi_accession_id
        assert_equal 'MGI:FAKE_CBX2_001', es_cell_2.mgi_accession_id
        assert_equal 'MGI:1923551', es_cell_3.mgi_accession_id
        assert_equal nil, es_cell_4.mgi_accession_id
      end

    end
  end
end

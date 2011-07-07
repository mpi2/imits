# encoding: utf-8

require 'test_helper'

module Cron
  class SyncEsCellsWithMartsTest < ExternalScriptTestCase
    context './script/cron/sync_es_cells_with_marts' do

      should 'work' do
        es_cells = [
          Factory.create(:es_cell, :name => 'EPD0127_4_E01'),
          Factory.create(:es_cell, :name => 'EPD0343_1_H06'),
          Factory.create(:es_cell, :name => 'EPD_NONEXISTENT_1')
        ]

        run_script './script/cron/sync_es_cells_with_marts'

        es_cells.each(&:reload)
        assert_equal 'Trafd1', es_cells[0].marker_symbol
        assert_equal 'Myo1c', es_cells[1].marker_symbol
      end

    end
  end
end

# encoding: utf-8

require 'test_helper'

class SyncClonesWithMartsTest < ExternalScriptTestCase
  context './script/sync_clones_with_marts' do

    should 'work' do
      clones = [
        Factory.create(:clone, :clone_name => 'EPD0127_4_E01'),
        Factory.create(:clone, :clone_name => 'EPD0343_1_H06'),
        Factory.create(:clone, :clone_name => 'EPD_NONEXISTENT_1')
      ]

      run_script './script/cron/sync_clones_with_marts'

      clones.each(&:reload)
      assert_equal 'Trafd1', clones[0].marker_symbol
      assert_equal 'Myo1c', clones[1].marker_symbol
    end

  end
end

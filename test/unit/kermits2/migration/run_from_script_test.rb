# encoding: utf-8

require 'test_helper'
require 'open3'

class Kermits2::Migration::RunFromScriptTest < ActiveSupport::TestCase
  def database_strategy; :deletion; end

  context 'Kermits2::Migration when run from script' do

    setup do
      Pipeline.destroy_all
      Centre.destroy_all
      assert_equal 0, MiAttempt.count
    end

    def run_script(commands)
      error_output = nil
      exit_status = nil
      Open3.popen3(commands) do
        |scriptin, scriptout, scripterr, wait_thr|
        error_output = scripterr.read
        exit_status = wait_thr.value.exitstatus
      end

      sleep 3

      assert_blank error_output, "Script has output to STDERR:\n#{error_output}"
      assert_equal 0, exit_status, "Script exited with error code #{exit_status}"
    end

    should 'works when invoked directly with just one mi attempt' do
      run_script "#{Rails.root}/script/runner -e test 'Kermits2::Migration.run(:mi_attempt_ids => [11029])'"

      assert_equal 1, MiAttempt.count
    end

    should 'work when invoked as ./script/data_migration' do
      run_script "cd #{Rails.root}; ./script/data_migration"
      assert_equal Old::MiAttempt.count, MiAttempt.count
    end

  end
end

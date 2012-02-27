# encoding: utf-8

require 'test_helper'

class ExternalScriptTestCaseTest < Kermits2::ExternalScriptTestCase
  context 'Kermits2::ExternalScriptTestCase tests:' do

    context '#run_script' do
      should 'run in test environment' do
        script_env = run_script('./script/runner "puts Rails.env"').strip
        assert_equal 'test', script_env
      end
    end

  end
end
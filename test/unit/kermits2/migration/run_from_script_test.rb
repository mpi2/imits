# encoding: utf-8

require 'test_helper'

class Kermits2::Migration::RunFromScriptTest < ExternalScriptTestCase
  context 'Kermits2::Migration when run from script' do

    setup do
      Pipeline.destroy_all
      Centre.destroy_all
      assert_equal 0, MiAttempt.count
    end

    should 'works when invoked directly with just one mi attempt' do
      run_script "./script/runner 'Kermits2::Migration.run(:mi_attempt_ids => [11029])'"

      assert_equal 1, MiAttempt.count
    end

    should_eventually 'work when invoked as ./script/data_migration' do
      run_script "./script/data_migration"
      assert_equal Old::MiAttempt.count, MiAttempt.count
      cursor = Old::Clone.connection.execute("select count(distinct emi_clone.clone_name) from emi_attempt inner join emi_event on emi_event.id = emi_attempt.event_id  inner join emi_clone on emi_clone.id = emi_event.clone_id")
      number_of_distinct_clones = cursor.fetch.first.to_i
      assert_equal number_of_distinct_clones, Clone.count
    end

  end
end

# encoding: utf-8

require 'test_helper'

class LoadInterestDataTest < ExternalScriptTestCase
  context './script/load_interest_data' do

    class MiPlan < ActiveRecord::Base
      self.establish_connection IN_MEMORY_MODEL_CONNECTION_PARAMS

      self.connection.create_table :mi_plans, :force => true do |t|
        t.text :mi_plan_priority_name
        t.text :mi_plan_status_name
        t.text :production_centre_name
        t.text :gene_name
        t.text :consortium_name
      end

      validates :name, :uniqueness => true
    end

    def sample_data_file(name)
      return File.expand_path(File.join(Rails.root, "test/sample_input_data/#{name}.csv"))
    end

    should 'work' do
      assert_equal 0, Gene.count
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/mrc'}"
      assert output.blank?

      assert_equal 2, Gene.count
    end

  end
end

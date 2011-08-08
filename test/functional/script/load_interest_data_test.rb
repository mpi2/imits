# encoding: utf-8

require 'test_helper'

class LoadInterestDataTest < ExternalScriptTestCase
  context './script/load_interest_data' do

    def sample_data_file(name)
      return File.expand_path(File.join(Rails.root, "test/sample_input_data/#{name}.csv"))
    end

    should 'create a MiPlan per row of data' do
      assert_equal 0, Gene.count
      assert_equal 0, MiPlan.count

      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/mrc'}"
      assert output.blank?

      gene = Gene.find_by_mgi_accession_id!('MGI:88289')
      assert_equal 'Cbx2', gene.marker_symbol

      assert_equal 1, gene.mi_plans.size
      mi_plan = gene.mi_plans.first
      assert_equal 'Interest', mi_plan.mi_plan_status.name
      assert_equal 'BaSH', mi_plan.consortium.name
      assert_equal 'MRC - Harwell', mi_plan.production_centre.name
      assert_equal 'High', mi_plan.mi_plan_priority.name

      assert_equal 2, Gene.count
      assert_equal 2, MiPlan.count
    end

    should 'set priority correctly' do
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/wtsi'}"
      assert output.blank?

      mi_plan = Gene.find_by_mgi_accession_id!('MGI:1338859').mi_plans.first
      assert_equal 'Medium', mi_plan.mi_plan_priority.name

      mi_plan = Gene.find_by_mgi_accession_id!('MGI:1346877').mi_plans.first
      assert_equal 'Low', mi_plan.mi_plan_priority.name
    end

    should 'ignore non-breeding start points' do
      assert_equal 0, MiPlan.count
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/wtsi'}"
      assert output.blank?

      assert_nil Gene.find_by_mgi_accession_id('MGI:1352750')
      assert_equal 4, MiPlan.count
    end

    should 'load in data from multiple consortia' do
      assert_equal 0, MiPlan.count
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/mrc'}"
      assert output.blank?
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/wtsi'}"
      assert output.blank?
      output = run_script "./script/load_interest_data.rb #{sample_data_file 'conflict_report/monterotondo'}"
      assert output.blank?

      assert_equal 3, Gene.find_by_mgi_accession_id('MGI:88289').mi_plans.size
    end

  end
end

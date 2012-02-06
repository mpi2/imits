# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::BaseTest < ActiveSupport::TestCase

  class TestReport < Reports::MiProduction::Base
    def self.refresh_report
      @@report = Table(%w[col1 col2 col3],
        :data => [
          [rand(999), rand(888), rand(777)],
          [rand(999), rand(888), rand(777)],
          [rand(999), rand(888), rand(777)]
        ]
      )
      @@report = @@report.sort_rows_by('col2')
    end

    def self.generate
      return @@report
    end

    def self.report_name; 'test_report'; end
  end

  context 'Reports::MiProduction::Base' do

    context '::generate_and_cache' do
      should 'store generated CSV in reports cache table' do
        assert_equal 0, ReportCache.count
        TestReport.generate_and_cache
        assert_equal 1, ReportCache.count
        cache = ReportCache.first
        assert_equal 'test_report', cache.name
        assert_equal TestReport.generate.to_csv, cache.csv_data
      end

      should 'store generated HTML in reports cache table' do
        assert_equal 0, ReportCache.count
        TestReport.generate_and_cache
        assert_equal 1, ReportCache.count
        cache = ReportCache.first
        assert_equal 'test_report', cache.name
        assert_equal TestReport.generate.to_html, cache.html_data
      end

      should 'replace existing reports cache if that exists' do
        TestReport.refresh_report
        TestReport.generate_and_cache
        old_cache = ReportCache.first

        sleep 1
        TestReport.refresh_report
        TestReport.generate_and_cache
        assert_equal 1, ReportCache.count
        new_cache = ReportCache.first

        assert_equal new_cache.name, old_cache.name
        assert_operator new_cache.updated_at, :>, old_cache.updated_at
        assert_equal TestReport.generate.to_csv, new_cache.csv_data
      end
    end

  end
end

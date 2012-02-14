# encoding: utf-8

require 'test_helper'

class Reports::BaseTest < ActiveSupport::TestCase

  class TestReport < Reports::Base
    def initialize
      @report = Ruport::Data::Table.new(:column_names => %w[col1 col2 col3],
        :data => [
          [rand(999), rand(888), rand(777)],
          [rand(999), rand(888), rand(777)],
          [rand(999), rand(888), rand(777)]
        ]
      )
      @report = @report.sort_rows_by('col2')
    end
    attr_reader :report

    def self.report_name; 'test_report'; end
  end

  context 'Reports::Base' do

    context '#cache' do
      should 'store generated CSV in reports cache table' do
        assert_equal 0, ReportCache.count
        report = TestReport.new
        report.cache
        assert_equal 1, ReportCache.count
        cache = ReportCache.first
        assert_equal 'test_report', cache.name
        assert_equal report.to(:csv), cache.csv_data
      end

      should 'store generated HTML in reports cache table' do
        assert_equal 0, ReportCache.count
        report = TestReport.new
        report.cache
        assert_equal 1, ReportCache.count
        cache = ReportCache.first
        assert_equal 'test_report', cache.name
        assert_equal report.to(:html), cache.html_data
      end

      should 'replace existing reports cache if that exists' do
        TestReport.new.cache
        old_cache = ReportCache.first

        sleep 1
        new_report = TestReport.new
        new_report.cache
        assert_equal 1, ReportCache.count
        new_cache = ReportCache.first

        assert_equal new_cache.name, old_cache.name
        assert_operator new_cache.updated_at, :>, old_cache.updated_at
        assert_equal new_report.to(:csv), new_cache.csv_data
      end
    end

    context '#to' do
      should 'get html' do
        report = TestReport.new
        assert_equal report.report.to_html, report.to(:html)
      end

      should 'get csv' do
        report = TestReport.new
        assert_equal report.report.to_csv, report.to(:csv)
      end
    end

  end
end

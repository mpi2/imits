# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::DetailTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::Detail' do
    setup do
      @bash_wtsi = Factory.create(:mi_plan,
        :consortium => Consortium.find_by_name!('BaSH'),
        :production_centre => Centre.find_by_name!('WTSI'))
      @ee_wtsi = Factory.create(:mi_plan,
        :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
        :production_centre => Centre.find_by_name!('WTSI'))
      @report = Reports::MiProduction::Detail.generate
    end

    should 'have columns in correct order' do
      expected = [
        'Consortium',
        'Production Centre',
        'Gene',
        #'Assigned date',
        #'ES Cells QC Complete date',
        #'Micro-injection in progress date',
        #'Genotype confirmed date',
        #'Micro-injection Aborted date'
      ]

      assert_equal expected, @report.column_names
    end
  end

end

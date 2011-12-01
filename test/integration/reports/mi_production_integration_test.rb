# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < Kermits2::JsIntegrationTest
  context 'MI production report' do

    setup do
      login
    end

    context '(detailed version)' do
      should 'render as HTML' do
        10.times { Factory.create :mi_plan }
        10.times { Factory.create :mi_attempt }
        sleep 3
        visit '/reports/mi_production'
        assert_equal 21, page.all('.report tr').size
        sleep 1
      end

      should 'be downloadable as CSV'
    end

  end
end

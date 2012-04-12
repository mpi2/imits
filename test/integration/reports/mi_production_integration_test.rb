# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < Kermits2::IntegrationTest
  context 'MI production reports:' do

    setup do
      create_common_test_objects
      Reports::MiProduction::Intermediate.new.cache
      login
    end

    context 'detailed MI production report' do
      should 'have link to cached report' do
        visit '/reports/mi_production/detail'
        assert page.has_css? "a[href='/reports/mi_production/detail.csv']"
      end
    end

  end
end

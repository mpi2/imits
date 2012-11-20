# encoding: utf-8

require 'test_helper'

class EsCellsControllerTest < ActionController::TestCase
  context 'EsCellsController' do

    setup do

      es_cell_hepd0549_6_d02 = Factory.create(:es_cell, :name => 'HEPD0549_6_D02', :allele => Factory.create(:allele))

      gene_trafd1 = Factory.create(:gene_trafd1)
      allele_trafd1 = Factory.create(:allele, :gene => gene_trafd1)

      @trafd1_es_cells = %w{
          EPD0127_4_B03
          EPD0127_4_F02
          EPD0127_4_A03
          EPD0127_4_E02
          EPD0127_4_D04
          EPD0127_4_F01
          EPD0127_4_B02
          EPD0127_4_E01
          EPD0127_4_F03
          EPD0127_4_C04
          EPD0127_4_F04
          EPD0127_4_H01
          EPD0127_4_E04
          EPD0127_4_B01
          EPD0127_4_A01
          EPD0127_4_A02
      }

      @trafd1_es_cells.each do |es_cell_name|
        Factory.create(:es_cell, :name => es_cell_name, :allele => allele_trafd1)
      end
      
    end

    should 'require authentication' do
      get :mart_search, :marker_symbol => 'Cbx1', :format => :json
      assert_false response.success?
    end

    context 'GET mart_search' do
      setup do
        sign_in default_user
      end

      should 'work with es_cell_name param' do
        get :mart_search, :es_cell_name => 'HEPD0549_6_D02', :format => :json
        data = JSON.parse(response.body)
        assert_equal 'HEPD0549_6_D02', data[0]['name']
      end

      should 'return empty array if passing in blank es_cell_name' do
        get :mart_search, :es_cell_name => nil, :format => :json
        data = JSON.parse(response.body)
        assert_equal 0, data.size
      end

      should 'work with marker_symbol param' do

        get :mart_search, :marker_symbol => 'Trafd1', :format => :json
        data = JSON.parse(response.body)
        assert_equal @trafd1_es_cells.sort, data.map {|i| i['name']}.sort

      end

      should 'return empty array if passing in blank marker_symbol' do
        get :mart_search, :marker_symbol => nil, :format => :json
        data = JSON.parse(response.body)
        assert_equal 0, data.size
      end
    end

  end
end

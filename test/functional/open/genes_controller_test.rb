require 'test_helper'

class Open::GenesControllerTest < ActionController::TestCase
  context 'OpenGenesController' do

    should 'do not require authentication to get gene' do
      10.times { Factory.create :gene }
      get :index, :format => :json
      assert response.success?
    end

    should 'do not require authentication to view network graph' do
      10.times { Factory.create :gene }
      get :network_graph, :id => Gene.first.id, :format => :html
      assert response.success?
    end

  end
end

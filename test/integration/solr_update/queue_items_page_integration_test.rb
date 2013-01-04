# encoding: utf-8

require 'test_helper'

class SolrUpdate::QueueItemsPageIntegrationTest < TarMits::JsIntegrationTest
  context 'Solr update queue items page integration test' do

    should 'not show solr queue link if not admin user' do
      login default_user
      assert page.has_no_content?('Solr Update Queue')
    end

    should 'render a grid' do
      admin_user = ApplicationModel.uncached { Factory.create :admin_user }

      ApplicationModel.uncached do
        2.times { Factory.create :solr_update_queue_item_mi_attempt }
      end

      login admin_user
      click_link 'Solr Update Queue'
      wait_until_grid_loaded
      assert_equal 2, page.all('.x-grid-row').size
    end

  end
end

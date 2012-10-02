require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase

  context 'SolrUpdate::Observer::MiAttempt' do
    teardown do
      SolrUpdate::Queue.unstub(:enqueue_for_update)
      SolrUpdate::Queue.unstub(:enqueue_for_delete)
    end

    should 'enqueue update when an MiAttempt is changed' do
      mi = stub('mi_attempt', :id => 55)
      SolrUpdate::Queue.expects(:enqueue_for_update).with(mi)

      o = SolrUpdate::Observer::MiAttempt.new
      o.after_save(mi)
    end

    should 'enqueue deletion when an MiAttempt is deleted' do
      mi = stub('mi_attempt', :id => 55)
      SolrUpdate::Queue.expects(:enqueue_for_delete).with(mi)

      o = SolrUpdate::Observer::MiAttempt.new
      o.after_destroy(mi)
    end
  end

  context 'SolrUpdate::Observer::PhenotypeAttempt' do
    teardown do
      SolrUpdate::Queue.unstub(:enqueue_for_update)
      SolrUpdate::Queue.unstub(:enqueue_for_delete)
    end

    should 'enqueue update when PhenotypeAttempt is changed' do
      pa = stub('phenotype_attempt', :id => 74)
      SolrUpdate::Queue.expects(:enqueue_for_update).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_save(pa)
    end

    should 'enqueue deletion when PhenotypeAttempt is deleted ' do
      pa = stub('phenotype_attempt', :id => 74)
      SolrUpdate::Queue.expects(:enqueue_for_delete).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_destroy(pa)
    end
  end

end

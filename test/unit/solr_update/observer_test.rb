require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase

  context 'SolrUpdate::Observer::MiAttempt' do
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

    should 'not enqueue update or deletion if MiAttempt gene does not have mgi_accession_id'
  end

  context 'SolrUpdate::Observer::PhenotypeAttempt' do
    should 'enqueue update when a cre-excised PhenotypeAttempt is changed' do
      pa = stub('phenotype_attempt', :id => 74)
      SolrUpdate::Queue.expects(:enqueue_for_update).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_save(pa)
    end

    should 'enqueue deletion when a cre-excised PhenotypeAttempt is deleted ' do
      pa = stub('phenotype_attempt', :id => 74)
      SolrUpdate::Queue.expects(:enqueue_for_delete).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_destroy(pa)
    end

    should 'not enqueue update when a non-cre-excised PhenotypeAttempt is changed' do
      flunk
    end

    should 'enqueue a deletion when a cre-excised PhenotypeAttempt becomes non-cre-excised' do
      flunk
    end

    should 'not enqueue update or deletion if PhenotypeAttempt gene does not have mgi_accession_id, even if PhenotypeAttempt is cre excised' do
      flunk
    end
  end

end

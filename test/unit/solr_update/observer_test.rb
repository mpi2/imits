require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase

  context 'SolrUpdate::Observer::MiAttempt' do
    should 'tell the enqueuer that a MiAttempt is changed' do
      mi = stub('mi_attempt')
      SolrUpdate::Enqueuer.any_instance.expects(:mi_attempt_updated).with(mi)

      o = SolrUpdate::Observer::MiAttempt.new
      o.after_save(mi)
    end

    should 'tell the enqueuer that a MiAttempt is deleted' do
      mi = stub('mi_attempt')
      SolrUpdate::Enqueuer.any_instance.expects(:mi_attempt_destroyed).with(mi)

      o = SolrUpdate::Observer::MiAttempt.new
      o.after_destroy(mi)
    end
  end

  context 'SolrUpdate::Observer::PhenotypeAttempt' do
    should 'tell the enqueuer that a PhenotypeAttempt is changed' do
      pa = stub('phenotype_attempt')
      SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_updated).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_save(pa)
    end

    should 'tell the enqueuer that a PhenotypeAttempt is deleted' do
      pa = stub('phenotype_attempt')
      SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_destroyed).with(pa)

      o = SolrUpdate::Observer::PhenotypeAttempt.new
      o.after_destroy(pa)
    end
  end

end

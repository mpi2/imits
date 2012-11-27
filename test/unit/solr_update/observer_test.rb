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

  context 'SolrUpdate::Observer::AnyWithMiAttempts' do
    should 'tell the enqueuer that something that has mi_attempts has changed' do
      object = stub('object')
      SolrUpdate::Enqueuer.any_instance.expects(:any_with_mi_attempts_updated).with(object)
      o = SolrUpdate::Observer::AnyWithMiAttempts.new
      o.after_save(object)
    end
  end

  context 'SolrUpdate::Observer::DistributionCentre' do
    should 'tell the enqueuer that a MiAttempt::DistributionCentre is changed' do
      object = stub('object')
      SolrUpdate::Enqueuer.any_instance.expects(:update_mi_or_phenotype_attempt).with(object)
      o = SolrUpdate::Observer::DistributionCentres.new
      o.after_save(object)
    end

    should 'tell the enqueuer that a MiAttempt::DistributionCentre is deleted' do
      object = stub('object')
      SolrUpdate::Enqueuer.any_instance.expects(:update_mi_or_phenotype_attempt).with(object)
      o = SolrUpdate::Observer::DistributionCentres.new
      o.after_destroy(object)
    end
  end

  context 'SolrUpdate::Observer::Allele' do

    should 'enqueue a solr update when an allele changes' do
      allele = stub('allele')
      SolrUpdate::Enqueuer.any_instance.expects(:allele_updated).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_save allele
    end

    should 'enqueue a solr deletion when an allele destroyed' do
      allele = stub('allele')
      SolrUpdate::Enqueuer.any_instance.expects(:allele_destroyed).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_destroy allele
    end
  end

  context 'SolrUpdate::Observer::EsCell' do
    should 'enqueue a solr update an es_cell changes' do
      es_cell = stub('es_cell')

      SolrUpdate::Enqueuer.any_instance.expects(:es_cell_updated).with(es_cell)

      o = SolrUpdate::Observer::EsCell.new
      o.after_save es_cell
    end

    should 'enqueue a solr update when es_cell is deleted' do
      es_cell = stub('es_cell')

      SolrUpdate::Enqueuer.any_instance.expects(:es_cell_destroyed).with(es_cell)

      o = SolrUpdate::Observer::EsCell.new
      o.after_destroy es_cell
    end

  end

end

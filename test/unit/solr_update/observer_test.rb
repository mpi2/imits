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
      if Rails.configuration.enable_solr_phenotype_attempt
        pa = stub('phenotype_attempt')
        SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_updated).with(pa)

        o = SolrUpdate::Observer::PhenotypeAttempt.new
        o.after_save(pa)
      end
    end

    should 'tell the enqueuer that a PhenotypeAttempt is deleted' do
      if Rails.configuration.enable_solr_phenotype_attempt
        pa = stub('phenotype_attempt')
        SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_destroyed).with(pa)

        o = SolrUpdate::Observer::PhenotypeAttempt.new
        o.after_destroy(pa)
      end
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

  context 'SolrUpdate::Observer::MiPlan' do
    should 'enqueue a solr update an mi_plan changes' do
      mi_plan = stub('mi_plan')

      SolrUpdate::Enqueuer.any_instance.expects(:mi_plan_updated).with(mi_plan)

      o = SolrUpdate::Observer::MiPlan.new
      o.after_save mi_plan
    end

    should 'enqueue a solr update when mi_plan is deleted' do
      mi_plan = stub('mi_plan')

      SolrUpdate::Enqueuer.any_instance.expects(:mi_plan_destroyed).with(mi_plan)

      o = SolrUpdate::Observer::MiPlan.new
      o.after_destroy mi_plan
    end

  end

  context 'SolrUpdate::Observer::Gene' do
    should 'enqueue a solr update an gene changes' do
      gene = stub('gene')

      SolrUpdate::Enqueuer.any_instance.expects(:gene_updated).with(gene)

      o = SolrUpdate::Observer::Gene.new
      o.after_save gene
    end

    should 'enqueue a solr update when gene is deleted' do
      gene = stub('gene')

      SolrUpdate::Enqueuer.any_instance.expects(:gene_destroyed).with(gene)

      o = SolrUpdate::Observer::Gene.new
      o.after_destroy gene
    end

  end

  context 'SolrUpdate::Observer::IkmcProject' do
    setup do
      gene = Factory.create :gene, :mgi_accession_id => 'MGI:9999999991'

      es_cell = stub("my es_cell")
      es_cell.stubs(:unique_public_info).returns([
        {:ikmc_project_name => 'project_name3', :ikmc_project_status_name => 'status_name3' },
        { :ikmc_project_name => '', :ikmc_project_status_name => '' }                             # check it doesn't get added
      ])

      status = stub("my status")
      status.stubs(:name).returns('Vector Complete')
      ikmc_project = stub("my ikmc_project")
      ikmc_project.stubs(:name).returns('project_name')
      ikmc_project.stubs(:status).returns(status)

      targeting_vector = stub("my targeting_vector")
      targeting_vector.stubs(:ikmc_project).returns(ikmc_project)

      allele = stub("my allele")
      allele.stubs(:es_cells).returns(es_cell)
      targeting_vector.stubs(:allele).returns(allele)
      allele.stubs(:gene).returns(gene)
      es_cell.stubs(:allele).returns(allele)

      @gene = gene

      ikmc_project.stubs(:targeting_vectors).returns([targeting_vector])
      ikmc_project.stubs(:es_cells).returns([es_cell])

      @ikmc_project = ikmc_project
    end

    should 'enqueue a solr update an gene changes' do
      SolrUpdate::Enqueuer.any_instance.expects(:gene_updated).with(@gene)
      o = SolrUpdate::Observer::IkmcProject.new
      o.after_save @ikmc_project
    end

    should 'enqueue a solr update when gene is deleted' do
      SolrUpdate::Enqueuer.any_instance.expects(:gene_updated).with(@gene)
      o = SolrUpdate::Observer::IkmcProject.new
      o.after_destroy @ikmc_project
    end

  end

end

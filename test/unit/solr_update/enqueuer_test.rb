require 'test_helper'

class SolrUpdate::EnqueuerTest < ActiveSupport::TestCase
  context 'SolrUpdate::Enqueuer' do

    setup do
      @gene = stub('gene', :mgi_accession_id => 'MGI:X1')
      @allele = stub('allele', :id => 44, :gene => @gene)
      @es_cell = stub('es_cell', :id => 642, :allele => @allele)
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    teardown do
      SolrUpdate::Queue.unstub(:enqueue_for_update)
      SolrUpdate::Queue.unstub(:enqueue_for_delete)
    end

    context 'when a mi_attempt changes' do
      should 'enqueue an update to it if it has status "gtc"' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 55
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => 55})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(mi.mi_plan.gene)
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue a deletion if it has been deleted' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 22
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'mi_attempt', 'id' => 22})
        @enqueuer.mi_attempt_destroyed(mi)
      end

      should 'not enqueue an update if mi_attempt gene does not have mgi_accession_id' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 55
        mi.gene.update_attributes!(:mgi_accession_id => nil)
        mi.reload
        SolrUpdate::Queue.expects(:enqueue_for_update).never
        @enqueuer.mi_attempt_updated(mi)
      end

      should_eventually 'not enqueue an update if mi_attempt is not linked to an allele' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 66
        mi.es_cell.update_attributes!(:allele_id => 0)
        mi.reload
        SolrUpdate::Queue.expects(:enqueue_for_update).never
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue a deletion for it if it does not have status "gtc"' do
        mi = Factory.create :mi_attempt2_status_chr, :id => 55
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'mi_attempt', 'id' => mi.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(mi.mi_plan.gene)
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue a deletion for it if it does has status "gtc" but is currently aborted' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 55, :is_active => false
        assert_equal 'abt', mi.status.code
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'mi_attempt', 'id' => mi.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(mi.mi_plan.gene)
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'tell itself the mi_attempt\'s phenotype attempts have been updated' do
        mi = Factory.create :mi_attempt2_status_gtc, :id => 67
        assert_equal 0, mi.phenotype_attempts.all.size

        pa1 = Factory.create :phenotype_attempt, :mi_attempt => mi, :id => 675
        pa2 = Factory.create :phenotype_attempt, :mi_attempt => mi, :id => 1475

        assert_equal [], mi.phenotype_attempts, 'The phenotype_attempts association is cached on the mi_attempt side BEFORE it\'s phenotype attempts are created, and we test that this behaviour does not mess up our enqueuer'

        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => mi.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'gene', 'id' => mi.mi_plan.id})
        @enqueuer.expects(:phenotype_attempt_updated).with(pa1)
        @enqueuer.expects(:phenotype_attempt_updated).with(pa2)

        @enqueuer.expects(:mi_plan_updated).with(mi.mi_plan)
        @enqueuer.expects(:mi_plan_updated).with(pa1.mi_plan)
        @enqueuer.expects(:mi_plan_updated).with(pa2.mi_plan)

        @enqueuer.mi_attempt_updated(mi)
      end
    end

    context 'when a phenotype_attempt changes' do
      should 'enqueue an update for it if it has status "cec"' do
        pa = Factory.create :phenotype_attempt_status_cec, :id => 67545
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => pa.mi_attempt.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(pa.mi_attempt)
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'phenotype_attempt', 'id' => pa.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(pa.mi_plan.gene)
        @enqueuer.phenotype_attempt_updated(pa)
      end

      should_eventually 'not enqueue an update if phenotype_attempt is not linked to an allele' do
        pa = Factory.create :phenotype_attempt_status_cec, :id => 345
        pa.mi_attempt.es_cell.update_attributes!(:allele_id => 0)
        pa.reload
        puts pa.inspect
        puts pa.es_cell.inspect
        SolrUpdate::Queue.expects(:enqueue_for_update).never
        @enqueuer.phenotype_attempt_updated(pa)
      end

      should 'enqueue a deletion for it if it does not have status "cec"' do
        pa = Factory.create :phenotype_attempt, :id => 345
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'phenotype_attempt', 'id' => pa.id})
        @enqueuer.phenotype_attempt_updated(pa)
      end

      should 'enqueue a deletion for it if it has been deleted' do
        pa = Factory.create :phenotype_attempt, :id => 568
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'phenotype_attempt', 'id' => pa.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => pa.mi_attempt.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(pa.mi_plan.gene)
        @enqueuer.phenotype_attempt_destroyed(pa)
      end

      should 'enqueue a deletion for it if it does has status "cec" but is currently aborted' do
        pa = Factory.create :phenotype_attempt_status_cec, :id => 345, :is_active => false
        assert_equal 'abt', pa.status.code
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'phenotype_attempt', 'id' => pa.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(pa.mi_plan.gene)
        @enqueuer.phenotype_attempt_updated(pa)
      end

    end

    context 'when anything with mi_attempts changes' do
      should_eventually 'tell itself that each of the changed object\'s mi_attempts have been updated' do
        mi1 = stub('mi1'); mi2 = stub('mi2')
        mi_attempts = stub('mi_attempts')
        has_mi_attempts = stub('has_mi_attempts', :changes => {'key' => ['old', 'new']})

        has_mi_attempts.expects(:mi_attempts).returns(mi_attempts)
        mi_attempts.expects(:reload).returns([mi1, mi2])
        @enqueuer.expects(:mi_attempt_updated).with(mi1)
        @enqueuer.expects(:mi_attempt_updated).with(mi2)

        #@enqueuer.expects(:mi_plan_updated).with(mi_attempts.mi_plan)
        @enqueuer.expects(:mi_plan_updated).with(mi1.mi_plan)
        @enqueuer.expects(:mi_plan_updated).with(mi2.mi_plan)

        @enqueuer.any_with_mi_attempts_updated(has_mi_attempts)
      end

      should 'not tell itself to enqueue the object\'s mi_attempts if it was not actually changed' do
        mi1 = stub('mi1'); mi2 = stub('mi2')
        mi_attempts = stub('mi_attempts')
        has_mi_attempts = stub('has_mi_attempts', :changes => {})

        has_mi_attempts.stubs(:mi_attempts).returns(mi_attempts)
        mi_attempts.stubs(:reload).returns([mi1, mi2])
        @enqueuer.expects(:mi_attempt_updated).never

        @enqueuer.any_with_mi_attempts_updated(has_mi_attempts)
      end
    end

    context '#update_mi_or_phenotype_attempt' do
      should 'just work with mi_attempt' do
        object = stub('distribution_centre')
        mi_attempt = stub('mi_attempt')
        object.stubs(:mi_attempt).returns(mi_attempt)
        object.expects("respond_to?").with('phenotype_attempt').returns(false)
        @enqueuer.expects(:mi_attempt_updated).with(mi_attempt)
        @enqueuer.update_mi_or_phenotype_attempt(object)
      end

      should 'just work with phenotype_attempt' do
        object = stub('distribution_centre')
        phenotype_attempt = stub('phenotype_attempt')
        object.stubs(:phenotype_attempt).returns(phenotype_attempt)
        object.expects("respond_to?").with('phenotype_attempt').returns(true)
        @enqueuer.expects(:phenotype_attempt_updated).with(phenotype_attempt)
        @enqueuer.update_mi_or_phenotype_attempt(object)
      end

    end

    context 'when an allele changes' do

      should 'enqueue an update for it if it has changed' do
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
        @enqueuer.allele_updated(@allele)
      end

      should 'enqueue a deletion if it has been deleted' do
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'allele', 'id' => 44})
        @enqueuer.allele_destroyed(@allele)
      end

      should 'enqueue its allele to be updated if its es_cell has changed' do
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
        @enqueuer.es_cell_updated(@es_cell)
      end

      should 'enqueue its allele to be updated if its es_cell is deleted' do
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
        @enqueuer.es_cell_destroyed(@es_cell)
      end
    end

    context 'when an mi_plan changes' do

      should 'enqueue an update for it if it has changed' do
        @gene = Factory.create :gene_cbx1
        @plan = Factory.create :mi_plan, :gene => @gene
        SolrUpdate::Queue.expects(:enqueue_for_update).with(@plan.gene)
        @enqueuer.mi_plan_updated(@plan)
      end

      should 'enqueue a deletion if it has been deleted' do
        @gene = Factory.create :gene_cbx1
        @plan = Factory.create :mi_plan, :gene => @gene
        SolrUpdate::Queue.expects(:enqueue_for_delete).with(@plan.gene)
        @enqueuer.mi_plan_destroyed(@plan)
      end

      should 'enqueue mi_plan to be updated if its mi_attempt has changed' do
        mi = Factory.create :mi_attempt2, :id => 33
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => 33})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(mi.mi_plan.gene)
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue mi_plan to be updated if its phenotype has changed' do
        pa = Factory.create :phenotype_attempt_status_cec, :id => 88
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => pa.mi_attempt.id})
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'phenotype_attempt', 'id' => 88})
        SolrUpdate::Queue.expects(:enqueue_for_update).with(pa.mi_plan.gene)
        @enqueuer.phenotype_attempt_updated(pa)
      end
    end

    context 'when a gene changes' do

      should 'enqueue an update for it if it has changed' do
        @gene = Factory.create :gene_cbx1
        SolrUpdate::Queue.expects(:enqueue_for_update).with(@gene)
        @enqueuer.gene_updated(@gene)
      end

      should 'enqueue a deletion if it has been deleted' do
        @gene = Factory.create :gene_cbx1
        SolrUpdate::Queue.expects(:enqueue_for_delete).with(@gene)
        @enqueuer.gene_destroyed(@gene)
      end

    end

  end
end

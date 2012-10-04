require 'test_helper'

class SolrUpdate::EnqueuerTest < ActiveSupport::TestCase
  context 'SolrUpdate::Enqueuer' do

    setup do
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    teardown do
      SolrUpdate::Queue.unstub(:enqueue_for_update)
      SolrUpdate::Queue.unstub(:enqueue_for_delete)
    end

    context 'when a mi_attempt changes' do
      should 'enqueue an update to it if it has status "gtc"' do
        mi = Factory.create :mi_attempt_genotype_confirmed, :id => 55
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => 55})
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue a deletion if it has been deleted' do
        mi = Factory.create :mi_attempt_genotype_confirmed, :id => 22
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'mi_attempt', 'id' => 22})
        @enqueuer.mi_attempt_destroyed(mi)
      end

      should 'not enqueue an update if mi_attempt gene does not have mgi_accession_id' do
        mi = Factory.create :mi_attempt_genotype_confirmed, :id => 55
        mi.gene.update_attributes!(:mgi_accession_id => nil)
        mi.reload
        SolrUpdate::Queue.expects(:enqueue_for_update).never
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'enqueue a deletion for it if it does not have status "gtc"' do
        mi = Factory.create :mi_attempt_chimeras_obtained, :id => 55
        SolrUpdate::Queue.expects(:enqueue_for_update).never
        SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'mi_attempt', 'id' => mi.id})
        @enqueuer.mi_attempt_updated(mi)
      end

      should 'tell itself the mi_attempt\'s phenotype attempts have changed too' do
        mi = Factory.create :mi_attempt_genotype_confirmed, :id => 67
        pa1 = Factory.create :phenotype_attempt, :mi_attempt => mi, :id => 675
        pa2 = Factory.create :phenotype_attempt, :mi_attempt => mi, :id => 1475
        mi.reload

        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'mi_attempt', 'id' => mi.id})
        SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_updated).with(pa1)
        SolrUpdate::Enqueuer.any_instance.expects(:phenotype_attempt_updated).with(pa2)
        @enqueuer.mi_attempt_updated(mi)
      end
    end

    context 'when a phenotype_attempt changes' do
      should 'enqueue an update for it if it has status "cec"' do
        pa = Factory.create :phenotype_attempt_status_cec, :id => 67545
        SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'phenotype_attempt', 'id' => pa.id})
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
        @enqueuer.phenotype_attempt_destroyed(pa)
      end

    end

  end
end

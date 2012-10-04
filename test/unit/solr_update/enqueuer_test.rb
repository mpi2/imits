require 'test_helper'

class SolrUpdate::EnqueuerTest < ActiveSupport::TestCase
  context 'SolrUpdate::Enqueuer' do

    teardown do
      SolrUpdate::Queue.unstub(:enqueue_for_update)
      SolrUpdate::Queue.unstub(:enqueue_for_delete)
    end

    should 'update an MI attempt\'s phenotype attempts on update' do
      mi_attempt = Factory.create(:mi_attempt_genotype_confirmed, :id => 44)
      Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi_attempt, :id => 55)
      Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi_attempt, :id => 66)

      phenotype_attempt_refs = [
        {'id' => 55, 'type' => 'phenotype_attempt'},
        {'id' => 66, 'type' => 'phenotype_attempt'}
      ]

      @testobj.expects(:do).with(phenotype_attempt_refs[0], 'update')
      @testobj.expects(:do).with(phenotype_attempt_refs[1], 'update')

      @testobj.after_update({'id' => 44, 'type' => 'mi_attempt'})
    end

    should 'do nothing if phenotype attempt is passed in' do
      @testobj.expects(:do).never

      @testobj.after_update({'id' => 44, 'type' => 'phenotype_attempt'})
    end

    context 'when a mi_attempt changes' do
      should 'enqueue an update to it if it has status "gtc"' do
        flunk
      end

      should 'enqueue a deletion if it has been deleted'
      should 'not enqueue an update if mi_attempt gene does not have mgi_accession_id'
      should 'not enqueue an update when a non-"gtc" mouse is changed'
      should 'enqueue a deletion for it if it has left the "gtc" status'
      should 'enqueue updates to it\'s "cec" phenotype attempts'
    end

    context 'when a phenotype_attempt changes' do
      should 'enqueue an update to it if it has status "cec"'
      should 'enqueue a deletion for it if it has left the "cec" state'
      should 'enqueue a deletion for it if it has been deleted'
    end

  end
end

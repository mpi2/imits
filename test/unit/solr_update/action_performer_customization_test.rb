require 'test_helper'

class SolrUpdate::ActionPerformerCustomizationTest < ActiveSupport::TestCase
  context 'SolrUpdate::ActionPerformerCustomization' do
    setup do
      @testobj = stub('testobj')
      @testobj.extend(SolrUpdate::ActionPerformerCustomization)
    end

    should 'update an MI attempt\'s phenotype attempts on update' do
      mi_attempt = Factory.create(:mi_attempt_genotype_confirmed, :id => 44)
      Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi_attempt, :id => 55)
      Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi_attempt, :id => 66)

      phenotype_attempt_refs = [
        {'id' => 55, 'type' => 'phenotype_attempt'},
        {'id' => 66, 'type' => 'phenotype_attempt'}
      ]

      SolrUpdate::ActionPerformer.expects(:do).with(phenotype_attempt_refs[0], 'update')
      SolrUpdate::ActionPerformer.expects(:do).with(phenotype_attempt_refs[1], 'update')

      @testobj.after_update({'id' => 44, 'type' => 'mi_attempt'})
    end

    should 'do nothing if phenotype attempt is passed in' do
      SolrUpdate::ActionPerformer.after_delete({'id' => 44, 'type' => 'mi_attempt'})
      SolrUpdate::ActionPerformer.expects(:do).never

      @testobj.after_update({'id' => 44, 'type' => 'phenotype_attempt'})
    end

  end
end

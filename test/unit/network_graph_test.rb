# encoding: utf-8

require 'test_helper'

class NetworkGraphTest < ActiveSupport::TestCase
  context 'NetworkGraph' do

    context 'has nodes for' do
      context 'genes which' do
        should 'have a html label' do
          marker_symbol = "cpk1"
          id = "1"
          symbol = "G1"
          node = NetworkGraph::GeneNode.new(:symbol => symbol, :id => id, :marker_symbol => marker_symbol)
          expected = "<<table>" +
                   "<tr><td colspan=\"2\">Gene</td></tr>" +
                   "<tr><td>Marker Symbol:</td><td>#{marker_symbol}</td></tr>" +
                   "</table>>"
          got = node.label_html
          assert_equal expected, got
        end
      end

      context 'mi_plans and' do
        should 'have a html label' do
          mi_plan = Factory.create :mi_plan
          status = mi_plan.status_stamps.first.status
          id = mi_plan.id
          symbol = "PA1"
          consortium = "BaSH"
          centre = "WTSI"
          node = NetworkGraph::MiPlanNode.new(:symbol => symbol, :id => id, :consortium => consortium, :centre => centre, :url => "")
          expected = "<<table>" +
                     "<tr><td colspan=\"2\">Mi Plan</td></tr>" +
                     "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                     "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                     "<tr><td>#{status.name}:</td><td>#{status.created_at}</td></tr>" +
                     "</table>>"
          got = node.label_html
          assert_equal expected, got
        end
      end

      context 'mi_attempts and' do
        should 'have a html label' do
          mi_attempt = Factory.create :mi_attempt
          status = mi_attempt.status_stamps.first.status
          id = mi_attempt.id
          symbol = "PA1"
          consortium = "BaSH"
          centre = "WTSI"
          colony_background_strain = "blogs"
          test_cross_strain = "blogs"
          node = NetworkGraph::MiAttemptNode.new(:symbol => symbol, :id => id, :consortium => consortium, :centre => centre, :test_cross_strain => test_cross_strain, :colony_background_strain => colony_background_strain , :url => "")
          expected = "<<table>" +
                     "<tr><td colspan=\"2\">Mouse Production</td></tr>" +
                     "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                     "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                     "<tr><td>#{status.name}:</td><td>#{status.created_at}</td></tr>" +
                     "<tr><td>Colony background strain:</td><td>#{colony_background_strain}</td></tr>" +
                     "<tr><td>Test cross strain:</td><td>#{test_cross_strain}</td></tr>" +
                     "</table>>"
          got = node.label_html
          assert_equal expected, got
        end
      end

      context 'phenotypes and' do
        should 'have a html label' do
          phenotype_attempt = Factory.create :phenotype_attempt
          status = phenotype_attempt.status_stamps.first.status
          id = phenotype_attempt.id
          symbol = "PA1"
          consortium = "BaSH"
          centre = "WTSI"
          cre_deleter_strain = "blogs"
          node = NetworkGraph::PhenotypeAttemptNode.new(:symbol => symbol, :id => id, :consortium => consortium, :centre => centre, :cre_deleter_strain => cre_deleter_strain, :url => "")
          expected = "<<table>" +
                   "<tr><td colspan=\"2\">Phenotype Attempt</td></tr>" +
                   "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                   "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                   "<tr><td>Cre Deleter Strain:</td><td>#{cre_deleter_strain}</td></tr>" +
                   "<tr><td>#{status.name}:</td><td>#{status.created_at}</td></tr>" +
                   "</table>>"
            got = node.label_html
            assert_equal expected, got
        end
      end
    end

    should 'produce dot file' do
      gene = Factory.create :gene, :marker_symbol => 'blogs'
      es_cell = Factory.create :es_cell, :gene => Gene.find_by_id(gene.id), :name => 'blogs'
      mi_plan = Factory.create :mi_plan, :gene => Gene.find_by_id(gene.id), :consortium => Consortium.find_by_name('BaSH'), :production_centre => Centre.find_by_name('WTSI')
      mi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed, :mi_plan => mi_plan, :es_cell => es_cell
      phenotype_attempt = Factory.create :phenotype_attempt, :mi_plan => mi_plan, :mi_attempt => mi_attempt

      got = NetworkGraph.new(gene.id).dot_file

      assert_match /"G\d".*Gene.*blogs/, got
      assert_match /"P\d".*Mi Plan/, got
      assert_match /"PA1".*Phenotype Attempt/, got
      assert_match /"P2".*Mi Plan/, got
      assert_match /"MA1".*Mouse Production/, got

      assert_match /"G1" -> "P1"/, got
      assert_match /"P(1|2)" -> "PA1"/, got
      assert_match /"G1" -> "P2"/, got
      assert_match /"P(1|2)" -> "MA1"/, got
      assert_match /"MA1" -> "PA1"/, got


      expected = <<-EOL
{rank=same;"Gene";"G1"}
{rank=same;"Mi Plans";"P1";"P2"}
{rank=same;"Mouse Production";"MA1"}
{rank=same;"Phenotype Attempts";"PA1"}
      EOL

      got_lines = got.split("\n")
      expected_lines = expected.split("\n")

      expected_lines.each do |i|
        assert_include got_lines, i
      end
    end

  end
end

# encoding: utf-8

require 'test_helper'

class NetworkGraphTest < ActiveSupport::TestCase
  context 'NetworkGraph' do

    context 'has nodes for' do
      context 'genes which' do
        should 'have a html label' do
          gene = Factory.create :gene
          marker_symbol = gene.marker_symbol
          id = gene.id
          symbol = "G1"
          node = NetworkGraph::GeneNode.new(gene ,params= {:symbol => symbol, :url => ""})
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
          mi_plan = Factory.create :mi_plan_with_production_centre
          status = mi_plan.status_stamps.first
          current_status = mi_plan.status.name
          id = mi_plan.id
          symbol = "PA1"
          consortium = mi_plan.consortium.name
          centre = mi_plan.production_centre.name
          node = NetworkGraph::MiPlanNode.new(mi_plan, params= {:symbol => symbol, :url => ""})
          expected = "<<table>" +
                     "<tr><td colspan=\"2\">Mi Plan</td></tr>" +
                     "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                     "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                     "<tr><td>Current Status:</td><td>#{current_status}</td></tr>" +
                     "<tr><td>#{status.status.name}:</td><td>#{status.created_at.strftime "%d/%m/%Y"}</td></tr>" +
                     "</table>>"
          got = node.label_html
          assert_equal expected, got
        end
      end

      context 'mi_attempts and' do
        should 'have a html label' do
          mi_attempt = Factory.create :randomly_populated_mi_attempt
          id = mi_attempt.id
          status_stamps = mi_attempt.status_stamps.order("created_at DESC")
          symbol = "PA1"
          consortium = mi_attempt.consortium.name
          centre = mi_attempt.production_centre.name
          colony_background_strain = CGI.escapeHTML(mi_attempt.colony_background_strain.name)
          current_status = mi_attempt.status.name
          colony_name = mi_attempt.colony_name.to_s
          test_cross_strain = CGI.escapeHTML(mi_attempt.test_cross_strain.name)
          status_string = ''
          status_stamps.each do |status|
            status_string << "<tr><td>#{status.status.name}:</td><td>#{status.created_at.strftime "%d/%m/%Y"}</td></tr>"
          end
          node = NetworkGraph::MiAttemptNode.new(mi_attempt, params= {:symbol => symbol, :url => "" })
          expected = "<<table>" +
                     "<tr><td colspan=\"2\">Mouse Production</td></tr>" +
                     "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                     "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                     "<tr><td>Current Status:</td><td>#{current_status}</td></tr>" +
                     "#{status_string}" +
                     "<tr><td>Colony background strain:</td><td>#{colony_background_strain}</td></tr>" +
                     "<tr><td>Colony name:</td><td>#{colony_name}</td></tr>" +
                     "<tr><td>Test cross strain:</td><td>#{test_cross_strain}</td></tr>" +
                     "</table>>"
          got = node.label_html
          assert_equal expected, got
        end
      end

      context 'phenotypes and' do
        should 'have a html label' do
          phenotype_attempt = Factory.create :phenotype_attempt_status_cec
          statuses = phenotype_attempt.status_stamps.all
          id = phenotype_attempt.id
          symbol = "PA1"
          consortium = phenotype_attempt.consortium.name
          centre = phenotype_attempt.production_centre.name
          cre_deleter_strain = phenotype_attempt.deleter_strain.name
          current_status = phenotype_attempt.status.name
          colony_name = phenotype_attempt.colony_name.to_s
          all_statuses = ''
          statuses.each do |status|
            all_statuses << "<tr><td>#{status.status.name}:</td><td>#{status.created_at.strftime "%d/%m/%Y"}</td></tr>" 
          end
          node = NetworkGraph::PhenotypeAttemptNode.new(phenotype_attempt, params={ :symbol => symbol, :url => "" })
          expected = "<<table>" +
                   "<tr><td colspan=\"2\">Phenotype Attempt</td></tr>" +
                   "<tr><td>Consortium:</td><td>#{consortium}</td></tr>" +
                   "<tr><td>Centre:</td><td>#{centre}</td></tr>" +
                   "<tr><td>Current Status:</td><td>#{current_status}</td></tr>" +
                   "<tr><td>Cre Deleter Strain:</td><td>#{cre_deleter_strain}</td></tr>" +
                   "#{all_statuses}" +
                   "<tr><td>Colony name:</td><td>#{colony_name}</td></tr>" +
                   "</table>>"
            got = node.label_html
            assert_equal expected, got
        end
      end
    end

    should 'produce dot file' do
      gene = Factory.create :gene, :marker_symbol => 'blogs'
      es_cell = Factory.create :es_cell, :gene => Gene.find_by_id(gene.id), :name => 'blogs'
      mi_plan = Factory.create :mi_plan, :gene => Gene.find_by_id(gene.id), :consortium => Consortium.find_by_name('BaSH'), :production_centre => Centre.find_by_name('WTSI'), :force_assignment => true
      mi_attempt = Factory.create :mi_attempt2_status_gtc, :mi_plan => mi_plan, :es_cell => es_cell
      phenotype_attempt = Factory.create :phenotype_attempt, :mi_plan => mi_plan, :mi_attempt => mi_attempt

      got = NetworkGraph.new(gene.id).dot_file

      assert_match(/"G\d".*Gene.*blogs/, got)
      assert_match(/"P\d".*Mi Plan/, got)
      assert_match(/"PA1".*Phenotype Attempt/, got)
      assert_match(/"P2".*Mi Plan/, got)
      assert_match(/"MA1".*Mouse Production/, got)

      assert_match(/"G1" -> "P1"/, got)
      assert_match(/"P(1|2)" -> "PA1"/, got)
      assert_match(/"G1" -> "P2"/, got)
      assert_match(/"P(1|2)" -> "MA1"/, got)
      assert_match(/"MA1" -> "PA1"/, got)


      expected = <<-EOL
{rank=same;"Gene";"G1"}
{rank=same;"Plan";"P1";"P2"}
{rank=same;"Mouse Production";"MA1"}
{rank=same;"Phenotype Attempt";"PA1"}
      EOL

      got_lines = got.split("\n")
      expected_lines = expected.split("\n")

      expected_lines.each do |i|
        assert_include got_lines, i
      end
    end

  end
end

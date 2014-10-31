require 'test_helper'
require 'pp'

class ApplicationModel::DistributionCentreTest < ActiveSupport::TestCase
  context 'ApplicationModel::DistributionCentre' do

    context 'Creation' do

        # Distribution Network, Distribution Centre
        # "CMMR";"TCP"
        # "EMMA";"BCM"
        # "EMMA";"CNB"
        # "EMMA";"CNRS"
        # "EMMA";"Fleming"
        # "EMMA";"Harwell"
        # "EMMA";"HMGU"
        # "EMMA";"ICS"
        # "EMMA";"IMG"
        # "EMMA";"INFRAFRONTIER-IMG"
        # "EMMA";"Monterotondo"
        # "EMMA";"Oulu"
        # "EMMA";"VETMEDUNI"
        # "EMMA";"WTSI"
        # "MMRRC";"BCM"
        # "MMRRC";"UCD"
        # "";"BCM"
        # "";"Harwell"
        # "";"HMGU"
        # "";"ICS"
        # "";"IMG"
        # "";"INFRAFRONTIER-CNB"
        # "";"INFRAFRONTIER-Oulu"
        # "";"JAX"
        # "";"KOMP Repo"
        # "";"MARC"
        # "";"Monash"
        # "";"Monterotondo"
        # "";"RIKEN BRC"
        # "";"SEAT"
        # "";"TCP"
        # "";"UCD"
        # "";"WTSI"

        setup do

        end

        should 'create order links' do
            puts "--------------------------------------------------"
            puts "testing KOMP mi attempt distribution centre link"
            komp_midc                        = Factory.build :mi_attempt_distribution_centre
            komp_midc.distribution_network   = 'KOMP'
            komp_midc.centre_name            = 'KOMP Repo'
            komp_midc.start_date             = '2014-01-01'
            komp_midc.save!

            assert_equal ["KOMP", "http://www.komp.org/geneinfo.php?project=project_0001"], komp_midc.calculate_order_link

            puts "--------------------------------------------------"
            puts "testing KOMP phenotype attempt distribution centre link"
            komp_pdc                         = Factory.create :phenotype_attempt_distribution_centre

            # bodge because mouse allele mod only created/updated when phenotype attempt updated
            komp_pdc.phenotype_attempt.save!
            komp_pdc.reload
            komp_pdc.distribution_network    = 'KOMP'
            komp_pdc.centre_name             = 'KOMP Repo'
            komp_pdc.start_date              = '2014-01-01'
            komp_pdc.save!

            assert_equal ["KOMP", "http://www.komp.org/geneinfo.php?project=project_0002"], komp_pdc.calculate_order_link

            puts "--------------------------------------------------"
            puts "testing EMMA mi attempt distribution centre link"
            emma_midc                        = Factory.create :mi_attempt_distribution_centre
            emma_midc.distribution_network   = 'EMMA'
            emma_midc.is_distributed_by_emma = true
            emma_midc.centre_name            = 'BCM'
            emma_midc.start_date             = '2014-01-01'
            emma_midc.save!

            assert_equal ["EMMA", "http://www.emmanet.org/mutant_types.php?keyword=Auto-generated Symbol 3"], emma_midc.calculate_order_link

            puts "--------------------------------------------------"
            puts "testing MMRRC mi attempt distribution centre link"
            mmrrc_midc                        = Factory.create :mi_attempt_distribution_centre
            mmrrc_midc.distribution_network   = 'MMRRC'
            mmrrc_midc.centre_name            = 'BCM'
            mmrrc_midc.start_date             = '2014-01-01'
            mmrrc_midc.save!

            assert_equal ["MMRRC", "http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=Auto-generated Symbol 4"], mmrrc_midc.calculate_order_link

            puts "--------------------------------------------------"
            puts "testing KOMP mi out of date"
            komp_midc_ood                        = Factory.build :mi_attempt_distribution_centre
            komp_midc_ood.distribution_network   = 'KOMP'
            komp_midc_ood.centre_name            = 'KOMP Repo'
            komp_midc_ood.start_date             = '2014-01-01'
            komp_midc_ood.end_date               = '2014-02-01'
            komp_midc_ood.save!

            assert_equal [], komp_midc_ood.calculate_order_link
        end

    end

  end
end
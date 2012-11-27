# encoding: utf-8

require 'test_helper'

class TargRep::DistributionQcsControllerTest < ActionController::TestCase

  context "TargRep::DistributionQcsController" do

    should "create new distribution_qc" do
      es_cell = Factory.create(:es_cell)

      target = {
        :es_cell_id         => es_cell.id,
        :five_prime_sr_pcr  => ['pass', 'fail'].sample,
        :three_prime_sr_pcr => ['pass', 'fail'].sample,
        :copy_number        => ['pass', 'fail'].sample,
        :five_prime_lr_pcr  => ['pass', 'fail'].sample,
        :three_prime_lr_pcr => ['pass', 'fail'].sample,
        :thawing            => ['pass', 'fail'].sample,
        :loa                => ['pass', 'fail', 'passb'].sample,
        :loxp               => ['pass', 'fail'].sample,
        :lacz               => ['pass', 'fail'].sample,
        :chr1               => ['pass', 'fail'].sample,
        :chr8a              => ['pass', 'fail'].sample,
        :chr8b              => ['pass', 'fail'].sample,
        :chr11a             => ['pass', 'fail'].sample,
        :chr11b             => ['pass', 'fail'].sample,
        :chry               => ['pass', 'fail', 'passb'].sample,
        :karyotype_low      => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
        :karyotype_high     => [0.1, 0.2, 0.3, 0.4, 0.5].sample
      }

      assert_difference('TargRep::DistributionQc.count') do
        post :create, :format => :json, :distribution_qc => target
      end

      assert_response :success

      distribution_qc = TargRep::DistributionQc.last

    end

    should "update distribution_qc" do
      distribution_qc = Factory.create(:distribution_qc, { :es_cell_distribution_centre => Factory.create(:es_cell_distribution_centre) } )
      es_cell = distribution_qc.es_cell
      id = distribution_qc.id

      target = {
        :id                 => id,
        :five_prime_sr_pcr  => ['pass', 'fail'].sample,
        :three_prime_sr_pcr => ['pass', 'fail'].sample,
        :copy_number        => ['pass', 'fail'].sample,
        :five_prime_lr_pcr  => ['pass', 'fail'].sample,
        :three_prime_lr_pcr => ['pass', 'fail'].sample,
        :thawing            => ['pass', 'fail'].sample,
        :loa                => ['pass', 'fail', 'passb'].sample,
        :loxp               => ['pass', 'fail'].sample,
        :lacz               => ['pass', 'fail'].sample,
        :chr1               => ['pass', 'fail'].sample,
        :chr8a              => ['pass', 'fail'].sample,
        :chr8b              => ['pass', 'fail'].sample,
        :chr11a             => ['pass', 'fail'].sample,
        :chr11b             => ['pass', 'fail'].sample,
        :chry               => ['pass', 'fail', 'passb'].sample,
        :karyotype_low      => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
        :karyotype_high     => [0.1, 0.2, 0.3, 0.4, 0.5].sample
      }

      put :update, :format => :json, :id => id, :distribution_qc => target
      assert_response :success

    end
  end
end

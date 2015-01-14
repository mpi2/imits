require 'test_helper'

class MutagenesisFactorControllerTest < ActionController::TestCase
  test "should get crisprs" do
    get :crisprs
    assert_response :success
  end

  test "should get vector" do
    get :vector
    assert_response :success
  end

  test "should get oligo" do
    get :oligo
    assert_response :success
  end

end

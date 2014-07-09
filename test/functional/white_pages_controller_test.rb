require 'test_helper'

class WhitePagesControllerTest < ActionController::TestCase
  test "should get phone_lookup" do
    get :phone_lookup
    assert_response :success
  end

end

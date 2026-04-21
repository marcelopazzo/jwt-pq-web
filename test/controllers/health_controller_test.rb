require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "returns ok" do
    get up_url
    assert_response :success
    assert_equal "ok", response.body
  end
end

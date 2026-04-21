require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  PAGES = {
    "/" => "Post-quantum JWT for Ruby",
    "/quickstart" => "Quick start",
    "/algorithms" => "Algorithms",
    "/hybrid" => "Hybrid EdDSA + ML-DSA",
    "/security" => "Security",
    "/debugger" => "JWT debugger"
  }.freeze

  PAGES.each do |path, heading|
    test "GET #{path} returns success and contains heading" do
      get path
      assert_response :success
      assert_match heading, response.body
    end
  end
end

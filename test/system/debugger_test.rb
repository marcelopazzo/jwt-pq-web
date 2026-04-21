require "application_system_test_case"

class DebuggerTest < ApplicationSystemTestCase
  test "loading an ML-DSA-65 sample and verifying it shows signature valid" do
    visit "/debugger"

    click_on "Load ML-DSA-65 sample"

    assert_selector "[data-debugger-target='signature']", text: /Sample loaded/i, wait: 10

    click_on "Verify"

    assert_selector "[data-debugger-target='signature']", text: /Signature valid/i, wait: 15
    assert_selector "[data-debugger-target='header']", text: "ML-DSA-65"
  end
end

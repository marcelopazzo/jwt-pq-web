require "application_system_test_case"

class DebuggerTest < ApplicationSystemTestCase
  test "loading an ML-DSA-65 sample and verifying it shows signature valid" do
    visit "/debugger"

    within ".debugger__sample-buttons" do
      click_on "ML-DSA-65"
    end

    assert_selector "[data-debugger-target='statusMessage']", text: /Sample loaded/i, wait: 10

    click_on "Verify signature"

    assert_selector "[data-debugger-target='statusMessage']", text: /Signature valid/i, wait: 15
    assert_selector "[data-debugger-target='header']", text: "ML-DSA-65"
  end
end

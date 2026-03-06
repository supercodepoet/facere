require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  test "visiting sign up page shows registration form" do
    visit sign_up_path

    assert_text "Create your account"
    assert_text "Start your productivity journey today"
    assert_text "Create Account"
    assert_text "Terms of Service"
    assert_text "Privacy Policy"
  end

  test "sign up page shows segmented control" do
    visit sign_up_path

    within(".auth-segmented-control") do
      assert_text "Sign In"
      assert_text "Sign Up"
    end
  end

  test "sign up page shows OAuth provider buttons" do
    visit sign_up_path

    assert_text "Google"
    assert_text "Apple"
  end

  test "sign up page shows password requirements" do
    visit sign_up_path

    assert_text "At least 8 characters"
    assert_text "One uppercase letter"
    assert_text "One lowercase letter"
    assert_text "One number"
    assert_text "One special character"
  end

  test "sign up page switches to sign in via turbo frame" do
    visit sign_up_path

    within(".auth-segmented-control") do
      click_link "Sign In"
    end

    assert_text "Welcome back"
    assert_text "Sign in to continue your productivity journey"
  end

  test "sign up page shows branded panel" do
    visit sign_up_path

    within(".auth-brand-panel") do
      assert_text "Facere"
      assert_text "Your tasks, your way"
    end
  end
end

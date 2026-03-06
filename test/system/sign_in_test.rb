require "application_system_test_case"

class SignInTest < ApplicationSystemTestCase
  test "visiting sign in page shows login form" do
    visit sign_in_path

    assert_text "Welcome back"
    assert_text "Sign in to continue your productivity journey"
    assert_text "Sign In"
    assert_text "Forgot password?"
  end

  test "sign in page shows segmented control" do
    visit sign_in_path

    within(".auth-segmented-control") do
      assert_text "Sign In"
      assert_text "Sign Up"
    end
  end

  test "sign in page shows OAuth provider buttons" do
    visit sign_in_path

    assert_text "Google"
    assert_text "Apple"
  end

  test "sign in page switches to sign up via turbo frame" do
    visit sign_in_path

    within(".auth-segmented-control") do
      click_link "Sign Up"
    end

    assert_text "Create your account"
    assert_text "Start your productivity journey today"
  end

  test "sign in page shows branded panel" do
    visit sign_in_path

    within(".auth-brand-panel") do
      assert_text "Facere"
      assert_text "Your tasks, your way"
    end
  end
end

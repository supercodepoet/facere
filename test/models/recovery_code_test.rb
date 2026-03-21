require "test_helper"

class RecoveryCodeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "generate_for creates 10 codes by default" do
    codes = RecoveryCode.generate_for(@user)

    assert_equal 10, codes.length
    assert_equal 10, @user.recovery_codes.count
  end

  test "generate_for returns plaintext codes" do
    codes = RecoveryCode.generate_for(@user)

    codes.each do |code|
      assert_kind_of String, code
      assert_equal 10, code.length
    end
  end

  test "generate_for destroys existing codes first" do
    RecoveryCode.generate_for(@user)
    assert_equal 10, @user.recovery_codes.count

    RecoveryCode.generate_for(@user)
    assert_equal 10, @user.recovery_codes.count
  end

  test "code_digest is bcrypt hash not plaintext" do
    codes = RecoveryCode.generate_for(@user)
    stored = @user.recovery_codes.first

    assert stored.code_digest.start_with?("$2a$")
    assert_not_equal codes.first, stored.code_digest
  end

  test "matches? returns true for correct plaintext code" do
    codes = RecoveryCode.generate_for(@user)
    stored = @user.recovery_codes.first

    assert stored.matches?(codes.first)
  end

  test "matches? returns false for wrong code" do
    RecoveryCode.generate_for(@user)
    stored = @user.recovery_codes.first

    assert_not stored.matches?("wrongcode1")
  end

  test "consume! sets used_at" do
    RecoveryCode.generate_for(@user)
    code = @user.recovery_codes.first

    assert_nil code.used_at
    code.consume!
    assert_not_nil code.reload.used_at
  end

  test "used? returns correct state" do
    RecoveryCode.generate_for(@user)
    code = @user.recovery_codes.first

    assert_not code.used?
    code.consume!
    assert code.used?
  end
end

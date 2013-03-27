require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "relations" do
    u = User.find :first
    assert_respond_to u, :time_entries
  end

  test "required fields" do
    u = User.find :first
    assert_respond_to u, :superadmin
    assert_respond_to u, :username
  end

end

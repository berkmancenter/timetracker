require 'test_helper'

class TimeEntryTest < ActiveSupport::TestCase
  test "dates are validated" do
    te = TimeEntry.find(1)
    te.entry_date = '2009-02-31'
    assert_not_equal (te.valid?, true)
    
    te.entry_date = '2009-02-14'
    assert_valid(te)
  end

  test "various date formats" do
    te = TimeEntry.new 
    te.entry_date = '2009-4-12'

    te2 = TimeEntry.new
    ['2009-4-12','April 12, 2009','April 12 2009','4/12/2009','Apr 12 2009','2009-04-12'].each do|test_date_string|
      te2.entry_date = test_date_string
      assert te.entry_date == te2.entry_date
    end
  end

  test "required fields" do
    te = TimeEntry.new
    assert_not_equal(te.valid?, true)

    te.category = 'Test Category'
    assert_not_equal(te.valid?,true)

    te.entry_date = Time.now
    assert_valid(te)
  end

  test "valid year month" do
    te = TimeEntry.find(1)
    te.entry_date = '2009-02-28'
    assert te.year_month == '2009-2'
  end

  test "relations" do
    te = TimeEntry.find(1)
    assert_respond_to te, :user
  end

  test "decimal time makes some sense" do
    te = TimeEntry.find(1)
    te.decimal_time = 'asf'
    assert_not_equal(te.valid?, true)

    te.decimal_time = 10
    assert_valid(te)
  end

end

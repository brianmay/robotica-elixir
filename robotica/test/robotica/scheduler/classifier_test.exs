defmodule Robotica.Scheduler.Classifier.Test do
  use ExUnit.Case, async: true

  import Robotica.Scheduler.Classifier

  test "is weekday" do
    assert "weekday" not in classify_date(~D[2018-12-22])
    assert "weekday" not in classify_date(~D[2018-12-23])
    assert "weekday" in classify_date(~D[2018-12-24])
    assert "weekday" in classify_date(~D[2018-12-25])
    assert "weekday" in classify_date(~D[2018-12-26])
    assert "weekday" in classify_date(~D[2018-12-27])
    assert "weekday" in classify_date(~D[2018-12-28])
  end

  test "is saturday" do
    assert "saturday" in classify_date(~D[2018-12-22])
    assert "saturday" not in classify_date(~D[2018-12-23])
    assert "saturday" not in classify_date(~D[2018-12-24])
    assert "saturday" not in classify_date(~D[2018-12-25])
    assert "saturday" not in classify_date(~D[2018-12-26])
    assert "saturday" not in classify_date(~D[2018-12-27])
    assert "saturday" not in classify_date(~D[2018-12-28])
  end

  test "is sunday" do
    assert "sunday" not in classify_date(~D[2018-12-22])
    assert "sunday" in classify_date(~D[2018-12-23])
    assert "sunday" not in classify_date(~D[2018-12-24])
    assert "sunday" not in classify_date(~D[2018-12-25])
    assert "sunday" not in classify_date(~D[2018-12-26])
    assert "sunday" not in classify_date(~D[2018-12-27])
    assert "sunday" not in classify_date(~D[2018-12-28])
  end

  test "is christmas" do
    assert "christmas" not in classify_date(~D[2018-12-22])
    assert "christmas" not in classify_date(~D[2018-12-23])
    assert "christmas" not in classify_date(~D[2018-12-24])
    assert "christmas" in classify_date(~D[2018-12-25])
    assert "christmas" not in classify_date(~D[2018-12-26])
    assert "christmas" not in classify_date(~D[2018-12-27])
    assert "christmas" not in classify_date(~D[2018-12-28])
  end

  test "is bad day" do
    assert "bad_day" in classify_date(~D[2018-12-22])
    assert "bad_day" in classify_date(~D[2018-12-23])
    assert "bad_day" in classify_date(~D[2018-12-24])
    assert "bad_day" not in classify_date(~D[2018-12-25])
    assert "bad_day" in classify_date(~D[2018-12-26])
    assert "bad_day" in classify_date(~D[2018-12-27])
    assert "bad_day" in classify_date(~D[2018-12-28])
  end

  test "is good day" do
    assert "good_day" in classify_date(~D[2018-12-22])
    assert "good_day" in classify_date(~D[2018-12-23])
    assert "good_day" not in classify_date(~D[2018-12-24])
    assert "good_day" in classify_date(~D[2018-12-25])
    assert "good_day" not in classify_date(~D[2018-12-26])
    assert "good_day" not in classify_date(~D[2018-12-27])
    assert "good_day" not in classify_date(~D[2018-12-28])
  end

  test "is special_christmas" do
    assert "special_christmas" not in classify_date(~D[2018-12-22])
    assert "special_christmas" not in classify_date(~D[2018-12-23])
    assert "special_christmas" not in classify_date(~D[2018-12-24])
    assert "special_christmas" not in classify_date(~D[2018-12-25])
    assert "special_christmas" not in classify_date(~D[2018-12-26])
    assert "special_christmas" not in classify_date(~D[2018-12-27])
    assert "special_christmas" not in classify_date(~D[2018-12-28])
  end

  test "is evil_christmas" do
    assert "evil_christmas" in classify_date(~D[2018-12-22])
    assert "evil_christmas" in classify_date(~D[2018-12-23])
    assert "evil_christmas" in classify_date(~D[2018-12-24])
    assert "evil_christmas" in classify_date(~D[2018-12-25])
    assert "evil_christmas" in classify_date(~D[2018-12-26])
    assert "evil_christmas" in classify_date(~D[2018-12-27])
    assert "evil_christmas" in classify_date(~D[2018-12-28])
  end

  test "after christmas" do
    assert "after_christmas" not in classify_date(~D[2018-12-22])
    assert "after_christmas" not in classify_date(~D[2018-12-23])
    assert "after_christmas" not in classify_date(~D[2018-12-24])
    assert "after_christmas" in classify_date(~D[2018-12-25])
    assert "after_christmas" in classify_date(~D[2018-12-26])
    assert "after_christmas" in classify_date(~D[2018-12-27])
    assert "after_christmas" in classify_date(~D[2018-12-28])
  end

  test "before christmas" do
    assert "before_christmas" in classify_date(~D[2018-12-22])
    assert "before_christmas" in classify_date(~D[2018-12-23])
    assert "before_christmas" in classify_date(~D[2018-12-24])
    assert "before_christmas" in classify_date(~D[2018-12-25])
    assert "before_christmas" not in classify_date(~D[2018-12-26])
    assert "before_christmas" not in classify_date(~D[2018-12-27])
    assert "before_christmas" not in classify_date(~D[2018-12-28])
  end
end

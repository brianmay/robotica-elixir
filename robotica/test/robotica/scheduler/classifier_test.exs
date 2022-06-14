defmodule Robotica.Scheduler.Classifier.Test do
  use ExUnit.Case, async: true

  import Robotica.Scheduler.Classifier

  test "is weekday" do
    assert "weekday" not in classify_date(~D[2018-12-22]).classifications
    assert "weekday" not in classify_date(~D[2018-12-23]).classifications
    assert "weekday" in classify_date(~D[2018-12-24]).classifications
    assert "weekday" in classify_date(~D[2018-12-25]).classifications
    assert "weekday" in classify_date(~D[2018-12-26]).classifications
    assert "weekday" in classify_date(~D[2018-12-27]).classifications
    assert "weekday" in classify_date(~D[2018-12-28]).classifications
  end

  test "is saturday" do
    assert "saturday" in classify_date(~D[2018-12-22]).classifications
    assert "saturday" not in classify_date(~D[2018-12-23]).classifications
    assert "saturday" not in classify_date(~D[2018-12-24]).classifications
    assert "saturday" not in classify_date(~D[2018-12-25]).classifications
    assert "saturday" not in classify_date(~D[2018-12-26]).classifications
    assert "saturday" not in classify_date(~D[2018-12-27]).classifications
    assert "saturday" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is sunday" do
    assert "sunday" not in classify_date(~D[2018-12-22]).classifications
    assert "sunday" in classify_date(~D[2018-12-23]).classifications
    assert "sunday" not in classify_date(~D[2018-12-24]).classifications
    assert "sunday" not in classify_date(~D[2018-12-25]).classifications
    assert "sunday" not in classify_date(~D[2018-12-26]).classifications
    assert "sunday" not in classify_date(~D[2018-12-27]).classifications
    assert "sunday" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is christmas" do
    assert "christmas" not in classify_date(~D[2018-12-22]).classifications
    assert "christmas" not in classify_date(~D[2018-12-23]).classifications
    assert "christmas" not in classify_date(~D[2018-12-24]).classifications
    assert "christmas" in classify_date(~D[2018-12-25]).classifications
    assert "christmas" not in classify_date(~D[2018-12-26]).classifications
    assert "christmas" not in classify_date(~D[2018-12-27]).classifications
    assert "christmas" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is bad day" do
    assert "bad_day" in classify_date(~D[2018-12-22]).classifications
    assert "bad_day" in classify_date(~D[2018-12-23]).classifications
    assert "bad_day" in classify_date(~D[2018-12-24]).classifications
    assert "bad_day" not in classify_date(~D[2018-12-25]).classifications
    assert "bad_day" in classify_date(~D[2018-12-26]).classifications
    assert "bad_day" in classify_date(~D[2018-12-27]).classifications
    assert "bad_day" in classify_date(~D[2018-12-28]).classifications
  end

  test "is good day" do
    assert "good_day" in classify_date(~D[2018-12-22]).classifications
    assert "good_day" in classify_date(~D[2018-12-23]).classifications
    assert "good_day" not in classify_date(~D[2018-12-24]).classifications
    assert "good_day" in classify_date(~D[2018-12-25]).classifications
    assert "good_day" not in classify_date(~D[2018-12-26]).classifications
    assert "good_day" not in classify_date(~D[2018-12-27]).classifications
    assert "good_day" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is special_christmas" do
    assert "special_christmas" not in classify_date(~D[2018-12-22]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-23]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-24]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-25]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-26]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-27]).classifications
    assert "special_christmas" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is evil_christmas" do
    assert "evil_christmas" not in classify_date(~D[2018-12-22]).classifications
    assert "evil_christmas" not in classify_date(~D[2018-12-23]).classifications
    assert "evil_christmas" not in classify_date(~D[2018-12-24]).classifications
    assert "evil_christmas" in classify_date(~D[2018-12-25]).classifications
    assert "evil_christmas" not in classify_date(~D[2018-12-26]).classifications
    assert "evil_christmas" not in classify_date(~D[2018-12-27]).classifications
    assert "evil_christmas" not in classify_date(~D[2018-12-28]).classifications
  end

  test "is good_christmas" do
    assert "good_christmas" not in classify_date(~D[2018-12-22]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-23]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-24]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-25]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-26]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-27]).classifications
    assert "good_christmas" not in classify_date(~D[2018-12-28]).classifications
  end

  test "after christmas" do
    assert "after_christmas" not in classify_date(~D[2018-12-22]).classifications
    assert "after_christmas" not in classify_date(~D[2018-12-23]).classifications
    assert "after_christmas" not in classify_date(~D[2018-12-24]).classifications
    assert "after_christmas" in classify_date(~D[2018-12-25]).classifications
    assert "after_christmas" in classify_date(~D[2018-12-26]).classifications
    assert "after_christmas" in classify_date(~D[2018-12-27]).classifications
    assert "after_christmas" in classify_date(~D[2018-12-28]).classifications
  end

  test "before christmas" do
    assert "before_christmas" in classify_date(~D[2018-12-22]).classifications
    assert "before_christmas" in classify_date(~D[2018-12-23]).classifications
    assert "before_christmas" in classify_date(~D[2018-12-24]).classifications
    assert "before_christmas" in classify_date(~D[2018-12-25]).classifications
    assert "before_christmas" not in classify_date(~D[2018-12-26]).classifications
    assert "before_christmas" not in classify_date(~D[2018-12-27]).classifications
    assert "before_christmas" not in classify_date(~D[2018-12-28]).classifications
  end
end

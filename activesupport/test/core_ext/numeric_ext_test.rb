require 'abstract_unit'
require 'active_support/time'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/integer'

class NumericExtTimeAndDateTimeTest < ActiveSupport::TestCase
  def setup
    @now = Time.local(2005,2,10,15,30,45)
    @dtnow = DateTime.civil(2005,2,10,15,30,45)
    @seconds = {
      1.minute   => 60,
      10.minutes => 600,
      1.hour + 15.minutes => 4500,
      2.days + 4.hours + 30.minutes => 189000,
      5.years + 1.month + 1.fortnight => 161589600
    }
  end

  def test_units
    @seconds.each do |actual, expected|
      assert_equal expected, actual
    end
  end

  def test_intervals
    @seconds.values.each do |seconds|
      assert_equal seconds.since(@now), @now + seconds
      assert_equal seconds.until(@now), @now - seconds
    end
  end

  # Test intervals based from Time.now
  def test_now
    @seconds.values.each do |seconds|
      now = Time.now
      assert seconds.ago >= now - seconds
      now = Time.now
      assert seconds.from_now >= now + seconds
    end
  end

  def test_irregular_durations
    assert_equal @now.advance(:days => 3000), 3000.days.since(@now)
    assert_equal @now.advance(:months => 1), 1.month.since(@now)
    assert_equal @now.advance(:months => -1), 1.month.until(@now)
    assert_equal @now.advance(:years => 20), 20.years.since(@now)
    assert_equal @dtnow.advance(:days => 3000), 3000.days.since(@dtnow)
    assert_equal @dtnow.advance(:months => 1), 1.month.since(@dtnow)
    assert_equal @dtnow.advance(:months => -1), 1.month.until(@dtnow)
    assert_equal @dtnow.advance(:years => 20), 20.years.since(@dtnow)
  end

  def test_duration_addition
    assert_equal @now.advance(:days => 1).advance(:months => 1), (1.day + 1.month).since(@now)
    assert_equal @now.advance(:days => 7), (1.week + 5.seconds - 5.seconds).since(@now)
    assert_equal @now.advance(:years => 2), (4.years - 2.years).since(@now)
    assert_equal @dtnow.advance(:days => 1).advance(:months => 1), (1.day + 1.month).since(@dtnow)
    assert_equal @dtnow.advance(:days => 7), (1.week + 5.seconds - 5.seconds).since(@dtnow)
    assert_equal @dtnow.advance(:years => 2), (4.years - 2.years).since(@dtnow)
  end

  def test_time_plus_duration
    assert_equal @now + 8, @now + 8.seconds
    assert_equal @now + 22.9, @now + 22.9.seconds
    assert_equal @now.advance(:days => 15), @now + 15.days
    assert_equal @now.advance(:months => 1), @now + 1.month
    assert_equal @dtnow.since(8), @dtnow + 8.seconds
    assert_equal @dtnow.since(22.9), @dtnow + 22.9.seconds
    assert_equal @dtnow.advance(:days => 15), @dtnow + 15.days
    assert_equal @dtnow.advance(:months => 1), @dtnow + 1.month
  end

  def test_chaining_duration_operations
    assert_equal @now.advance(:days => 2).advance(:months => -3), @now + 2.days - 3.months
    assert_equal @now.advance(:days => 1).advance(:months => 2), @now + 1.day + 2.months
    assert_equal @dtnow.advance(:days => 2).advance(:months => -3), @dtnow + 2.days - 3.months
    assert_equal @dtnow.advance(:days => 1).advance(:months => 2), @dtnow + 1.day + 2.months
  end

  def test_duration_after_convertion_is_no_longer_accurate
    assert_equal 30.days.to_i.since(@now), 1.month.to_i.since(@now)
    assert_equal 365.25.days.to_f.since(@now), 1.year.to_f.since(@now)
    assert_equal 30.days.to_i.since(@dtnow), 1.month.to_i.since(@dtnow)
    assert_equal 365.25.days.to_f.since(@dtnow), 1.year.to_f.since(@dtnow)
  end

  def test_add_one_year_to_leap_day
    assert_equal Time.utc(2005,2,28,15,15,10), Time.utc(2004,2,29,15,15,10) + 1.year
    assert_equal DateTime.civil(2005,2,28,15,15,10), DateTime.civil(2004,2,29,15,15,10) + 1.year
  end

  def test_since_and_ago_anchored_to_time_now_when_time_zone_is_not_set
    Time.zone = nil
    with_env_tz 'US/Eastern' do
      Time.stubs(:now).returns Time.local(2000)
      # since
      assert_equal false, 5.since.is_a?(ActiveSupport::TimeWithZone)
      assert_equal Time.local(2000,1,1,0,0,5), 5.since
      # ago
      assert_equal false, 5.ago.is_a?(ActiveSupport::TimeWithZone)
      assert_equal Time.local(1999,12,31,23,59,55), 5.ago
    end
  end

  def test_since_and_ago_anchored_to_time_zone_now_when_time_zone_is_set
    Time.zone = ActiveSupport::TimeZone['Eastern Time (US & Canada)']
    with_env_tz 'US/Eastern' do
      Time.stubs(:now).returns Time.local(2000)
      # since
      assert_equal true, 5.since.is_a?(ActiveSupport::TimeWithZone)
      assert_equal Time.utc(2000,1,1,0,0,5), 5.since.time
      assert_equal 'Eastern Time (US & Canada)', 5.since.time_zone.name
      # ago
      assert_equal true, 5.ago.is_a?(ActiveSupport::TimeWithZone)
      assert_equal Time.utc(1999,12,31,23,59,55), 5.ago.time
      assert_equal 'Eastern Time (US & Canada)', 5.ago.time_zone.name
    end
  ensure
    Time.zone = nil
  end

  protected
    def with_env_tz(new_tz = 'US/Eastern')
      old_tz, ENV['TZ'] = ENV['TZ'], new_tz
      yield
    ensure
      old_tz ? ENV['TZ'] = old_tz : ENV.delete('TZ')
    end
end

class NumericExtDateTest < ActiveSupport::TestCase
  def setup
    @today = Date.today
  end

  def test_date_plus_duration
    assert_equal @today + 1, @today + 1.day
    assert_equal @today >> 1, @today + 1.month
    assert_equal @today.to_time.since(1), @today + 1.second
    assert_equal @today.to_time.since(60), @today + 1.minute
    assert_equal @today.to_time.since(60*60), @today + 1.hour
  end

  def test_chaining_duration_operations
    assert_equal @today.advance(:days => 2).advance(:months => -3), @today + 2.days - 3.months
    assert_equal @today.advance(:days => 1).advance(:months => 2), @today + 1.day + 2.months
  end

  def test_add_one_year_to_leap_day
    assert_equal Date.new(2005,2,28), Date.new(2004,2,29) + 1.year
  end
end

class NumericExtSizeTest < ActiveSupport::TestCase
  def test_unit_in_terms_of_another
    relationships = {
        1024.bytes     =>   1.kilobyte,
        1024.kilobytes =>   1.megabyte,
      3584.0.kilobytes => 3.5.megabytes,
      3584.0.megabytes => 3.5.gigabytes,
      1.kilobyte ** 4  =>   1.terabyte,
      1024.kilobytes + 2.megabytes =>   3.megabytes,
                   2.gigabytes / 4 => 512.megabytes,
      256.megabytes * 20 + 5.gigabytes => 10.gigabytes,
      1.kilobyte ** 5 => 1.petabyte,
      1.kilobyte ** 6 => 1.exabyte
    }

    relationships.each do |left, right|
      assert_equal right, left
    end
  end

  def test_units_as_bytes_independently
    assert_equal 3145728, 3.megabytes
    assert_equal 3145728, 3.megabyte
    assert_equal 3072, 3.kilobytes
    assert_equal 3072, 3.kilobyte
    assert_equal 3221225472, 3.gigabytes
    assert_equal 3221225472, 3.gigabyte
    assert_equal 3298534883328, 3.terabytes
    assert_equal 3298534883328, 3.terabyte
    assert_equal 3377699720527872, 3.petabytes
    assert_equal 3377699720527872, 3.petabyte
    assert_equal 3458764513820540928, 3.exabytes
    assert_equal 3458764513820540928, 3.exabyte
  end
end

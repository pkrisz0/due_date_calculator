require 'rspec/autorun'
require 'date'
require 'active_support/time'
require 'byebug'

class InvalidParamError < StandardError; end

class DueDateCalculator
  def calculate_due_date(submit_date, turnaround)
    return unless params_approved?(submit_date, turnaround)
    resolution_date(submit_date, turnaround)
  end

  def resolution_date(submit_date, turnaround)
    @days = turnaround / 8
    @hours = turnaround % 8

    @hours += 16 unless within_working_hours?(submit_date + @hours.hours)
    @days += 2 if (submit_date.wday + @days) > 5 || submit_date.wday == 5

    submit_date + @hours.hour + @days.days
  end

  def params_approved?(submit_date, turnaround)
    params_type_check(submit_date, turnaround) &&
    weekday?(submit_date) &&
    within_working_hours?(submit_date)
  end

  def params_type_check(submit_date, turnaround)
    submit_date.is_a?(DateTime) && !turnaround.nil? && turnaround > 0 && turnaround.is_a?(Integer) ? true : raise(InvalidParamError)
  end

  def weekday?(date)
    date.wday < 6
  end

  def within_working_hours?(date)
    after_or_at_nine = date.hour >= 9
    after_or_at_nine && (date.hour < 17 || (date.second == 0 && date.minute == 0 && date.hour == 17))
  end
end

describe DueDateCalculator do
  subject { described_class.new }
  turnaround = 9

  context 'inputs' do
    submit_date = '2019-09-10 13:00:00'.to_datetime

    it 'is a submit date and turnaround in hours' do
      expect { subject.calculate_due_date(submit_date, nil) }.to raise_error InvalidParamError
      expect { subject.calculate_due_date(nil, turnaround) }.to raise_error InvalidParamError
    end

    it 'is in a date and an integer format' do
      expect { subject.calculate_due_date(submit_date.to_s, turnaround) }.to raise_error InvalidParamError
      expect { subject.calculate_due_date(submit_date, turnaround.to_f) }.to raise_error InvalidParamError
    end
  end

  context 'submission date' do
    weekday = '2019-09-10 15:00:00'.to_datetime
    weekend = '2019-09-14 16:00:00'.to_datetime

    it 'is a weekday' do
      expect(subject.calculate_due_date(weekend, turnaround)).to be nil
      expect(subject.calculate_due_date(weekday, turnaround)).to be_a DateTime
    end

    too_soon = '2019-09-10 08:00:00'.to_datetime
    too_late = '2019-09-11 17:01:00'.to_datetime
    in_time = '2019-09-12 17:00:00'.to_datetime

    it 'is between 9AM and 5PM' do
      expect(subject.calculate_due_date(too_soon, turnaround))
      expect(subject.calculate_due_date(too_late, turnaround))
      expect(subject.calculate_due_date(in_time, turnaround)).to be_a DateTime
    end
  end

  context 'resolution date' do
    wednesday = '2019-09-11 12:38:00'.to_datetime

    it 'returns the same day if turnaround is within working hours' do
      expected_resolution = '2019-09-11 13:38:00'.to_datetime
      expect(subject.calculate_due_date(wednesday, 1)).to eq expected_resolution
    end

    it 'returns next day if resolution is after closing hour' do
      expected_resolution = '2019-09-12 10:38:00'.to_datetime
      expect(subject.calculate_due_date(wednesday, 6)).to eq expected_resolution
    end

    it 'friday last working hour should return monday' do
      expected_resolution = '2019-09-16 9:58:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-13 16:58:00'.to_datetime, 1)).to eq expected_resolution
    end

    it 'friday last working hour should return tuesday if turnaround is over a working day' do
      expected_resolution = '2019-09-17 9:58:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-13 16:58:00'.to_datetime, 9)).to eq expected_resolution
    end
  end
end
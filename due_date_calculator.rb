require 'rspec/autorun'
require 'date'
require 'active_support/time'
require 'byebug'

class InvalidParamsError < StandardError; end

class DueDateCalculator
  def calculate_due_date(submit_date, turnaround)
    raise InvalidParamsError unless params_approved?(submit_date, turnaround)

    resolution_date(submit_date, turnaround)
  end

  def resolution_date(submit_date, turnaround)
    @weeks = turnaround / 40
    @days = turnaround / 8
    @hours = turnaround % 8

    weekend_days = @weeks > 1 ? 2 * @weeks : 2

    @days += weekend_days if turnaround_includes_weekend?(submit_date.wday + @days) || (friday?(submit_date) && !within_working_hours?(submit_date + @hours.hours))
    @hours += 16  unless within_working_hours?(submit_date + @hours.hours)

    submit_date + @hours.hour + @days.days
  end

  def params_approved?(submit_date, turnaround)
    params_types_match?(submit_date, turnaround) &&
    weekday?(submit_date) &&
    within_working_hours?(submit_date)
  end

  def params_types_match?(submit_date, turnaround)
    submit_date.is_a?(DateTime) && !turnaround.nil? && turnaround.positive? && turnaround.is_a?(Integer)
  end

  def weekday?(date)
    date.wday < 6
  end

  def friday?(date)
    date.wday == 5
  end

  def turnaround_includes_weekend?(date)
     date > 5
  end

  def within_working_hours?(date)
    after_or_at_nine = date.hour >= 9
    after_or_at_nine && (date.hour < 17 || (date.second.zero? && date.minute.zero? && date.hour == 17))
  end
end

describe DueDateCalculator do
  subject { described_class.new }
  turnaround = 9

  context 'inputs' do
    submit_date = '2019-09-10 13:00:00'.to_datetime

    it 'is a submit date and turnaround in hours' do
      expect { subject.calculate_due_date(submit_date, nil) }.to raise_error InvalidParamsError
      expect { subject.calculate_due_date(nil, turnaround) }.to raise_error InvalidParamsError
    end

    it 'is in a date and an integer format' do
      expect { subject.calculate_due_date(submit_date.to_s, turnaround) }.to raise_error InvalidParamsError
      expect { subject.calculate_due_date(submit_date, turnaround.to_f) }.to raise_error InvalidParamsError
    end
  end

  context 'submission date' do
    tuesday = '2019-09-10 15:00:00'.to_datetime
    weekend = tuesday + 4.days

    it 'is a weekday' do
      expect { subject.calculate_due_date(weekend, turnaround) }.to raise_error InvalidParamsError
      expect(subject.calculate_due_date(tuesday, turnaround)).to be_a DateTime
    end

    in_time = '2019-09-12 17:00:00'.to_datetime
    too_soon = in_time - 9.hours
    too_late = in_time + 1.minute

    it 'is between 9AM and 5PM' do
      expect { subject.calculate_due_date(too_soon, turnaround) }.to raise_error InvalidParamsError
      expect { subject.calculate_due_date(too_late, turnaround) }.to raise_error InvalidParamsError
      expect(subject.calculate_due_date(in_time, turnaround)).to be_a DateTime
    end
  end

  context 'resolution date' do
    wednesday = '2019-09-11 12:38:00'.to_datetime

    it 'returns the same day if turnaround is within working hours' do
      expected_resolution = '2019-09-11 13:38:00'.to_datetime
      expect(subject.calculate_due_date(wednesday, 1)).to eq expected_resolution
    end

    it 'returns the same day if turnaround is within working hours on a friday' do
      expected_resolution = '2019-09-13 14:38:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-13 13:38:00'.to_datetime, 1)).to eq expected_resolution
    end

    it 'returns next day if resolution is after closing hour' do
      expected_resolution = '2019-09-12 10:38:00'.to_datetime
      expect(subject.calculate_due_date(wednesday, 6)).to eq expected_resolution
    end

    it 'returns first day next week if submitted on friday during last working hour' do
      expected_resolution = '2019-09-16 9:58:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-13 16:58:00'.to_datetime, 1)).to eq expected_resolution
    end

    it 'returns second day of next week if submitted during last day of week and takes over a working day to resolve' do
      expected_resolution = '2019-09-17 11:58:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-13 16:58:00'.to_datetime, 11)).to eq expected_resolution
    end

    it 'calculates multiple weekends for 3 weeks' do
      expected_resolution = '2019-09-23 14:12:00'.to_datetime
      expect(subject.calculate_due_date('2019-09-02 14:12:00'.to_datetime, 120)).to eq expected_resolution
    end
  end
end

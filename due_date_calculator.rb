require 'rspec/autorun'
require 'date'
require 'active_support/time'
require 'byebug'

class InvalidParamError < StandardError; end
class SubmissionDateError < StandardError; end

class DueDateCalculator
  def calculate_due_date(submit_date, turnaround)
    return unless params_approved?(submit_date, turnaround)
    resolution_date = submit_date
  end

  def params_approved?(submit_date, turnaround)
    params_type_check(submit_date, turnaround) &&
        submit_date_check(submit_date) &&
        working_hours_check(submit_date)
  end

  def params_type_check(submit_date, turnaround)
    submit_date.is_a?(DateTime) && turnaround.is_a?(Integer) ? true : raise(InvalidParamError)
  end

  def submit_date_check(submit_date)
    submit_date.wday < 6 ? true : raise(SubmissionDateError)
  end

  def working_hours_check(submit_date)
    after_or_at_nine = submit_date.hour >= 9
    before_or_at_five = (submit_date.hour < 17 || (submit_date.minute == 0 && submit_date.hour == 17))
    after_or_at_nine && before_or_at_five ? true : raise(SubmissionDateError)
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

    it 'has to be a weekday' do
      expect { subject.calculate_due_date(weekend, turnaround) }.to raise_error SubmissionDateError
      expect(subject.calculate_due_date(weekday, turnaround)).to be_a DateTime
    end

    too_soon = '2019-09-10 08:00:00'.to_datetime
    too_late = '2019-09-11 17:01:00'.to_datetime
    in_time = '2019-09-12 17:00:00'.to_datetime

    it 'has to be between 9AM and 5PM' do
      expect { subject.calculate_due_date(too_soon, turnaround) }.to raise_error SubmissionDateError
      expect { subject.calculate_due_date(too_late, turnaround) }.to raise_error SubmissionDateError
      expect(subject.calculate_due_date(in_time, turnaround)).to be_a DateTime
    end
  end
end
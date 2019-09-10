require 'rspec/autorun'
require 'date'
require 'byebug'


class InvalidParamError < StandardError; end

class DueDateCalculator
  def calculate_due_date(submit_date, turnaround)
    return unless params_approved?(submit_date, turnaround)
    resolution_date = submit_date
  end

  def params_approved?(submit_date, turnaround)
    params_type_check(submit_date, turnaround)
  end

  def params_type_check(submit_date, turnaround)
    raise InvalidParamError, message: "Invalid Type" unless submit_date.is_a?(DateTime) && turnaround.is_a?(Integer)
    true
  end
end


describe DueDateCalculator do
  subject { described_class.new }

  context 'inputs' do
    turnaround = 9
    submit_date = DateTime.now

    it 'is a submit date and turnaround in hours' do
      expect { subject.calculate_due_date(submit_date, nil) }.to raise_error InvalidParamError
      expect { subject.calculate_due_date(nil, submit_date) }.to raise_error InvalidParamError
    end

    it 'is in a date and an integer format' do
      expect { subject.calculate_due_date(submit_date.to_s, turnaround) }.to raise_error InvalidParamError
      expect { subject.calculate_due_date(submit_date, turnaround.to_f) }.to raise_error InvalidParamError
    end
  end

  context 'output' do
    it 'returns a date and time' do
      expect(subject.calculate_due_date(DateTime.now, 9)).to be_a DateTime
    end
  end
end
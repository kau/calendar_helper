require 'spec_helper'

describe CalendarHelper, "#calendar" do
  def calendar options = {}, &block
    CalendarHelper.calendar options, &block
  end
  
  def current_calendar options = {}, &block
    options = { :year => Time.now.year, :month => Time.now.month}.merge options
    CalendarHelper.calendar options, &block
  end
  
  it "should require both month and year arguments" do
    lambda { calendar }.should raise_error(ArgumentError, "No year given")
  end
  
  it "should require a year argument" do
    lambda { calendar(:month => 1) }.should raise_error(ArgumentError, "No year given")
  end
  
  it "should require a month argument" do
      lambda { calendar(:year => 1) }.should raise_error(ArgumentError, "No month given")
  end
  
  it "should render a calendar for the specified month" do
    current_calendar.should match %r{#{Date::MONTHNAMES[Time.now.month]}}
  end

  it "should render previous month text" do
    current_calendar(:previous_month_text => "PREVIOUS").should match %r{<tr>.*<td colspan="2">PREVIOUS</td>}m
  end

  it "should render next month text" do
    current_calendar(:next_month_text => "NEXT").should match %r{<tr>.*<td colspan="2">NEXT</td>}m
  end
  
  it "should render default css class names" do
    { :table_class => "calendar",
      :month_name_class => "monthName",
      :day_name_class => "dayName",
      :day_class => "day"
    }.each do |key, value|
      current_calendar(key => value).should match %r{class="#{value}"}
    end
  end
  
  it "should render custom css class names" do
    [:table_class, :month_name_class, :day_name_class, :day_class].each do |key|
      current_calendar(key => key.to_s).should match %r{class="#{key.to_s}"}
    end
  end
  
  it "should render day name abbreviations of specified length" do
    current_calendar(:abbrev => (0..2)).should match %r{>Mon<}
  end

  it "should set cell text and attrs when supplied a block" do
    calendar(:year => 2006, :month => 8) do |d|
      if d.mday % 2 == 0
        ["-#{d.mday}-", {:class => 'special_day'}]
      end
    end.should match %r{class="special_day">-2-<}
  end

  it "should default to weeks starting with Sunday" do
    current_calendar.should match %r{<tr class="dayName">.*<th scope="col">.*<abbr title="Sunday">Sun}m
  end
  
  it "should start weeks with specified day" do
    current_calendar(:first_day_of_week => 1).should match %r{<tr class="dayName">.*<th scope="col">.*<abbr title="Monday">Mon}m
  end

  it "should add css class to today by default" do
    todays_day = Date.today.day
    current_calendar.should match %r{today}
  end
  
  it "should allow css class for today to be suppressed" do
    todays_day = Date.today.day
    current_calendar(:show_today => false).should_not match %r{today}
  end
  
  it "should render valid xhtml" do
    current_calendar.should be_valid_xhtml_fragment
  end
end

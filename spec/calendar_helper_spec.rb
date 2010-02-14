require 'calendar_helper'
include CalendarHelper
require 'be_valid_asset'
include BeValidAsset

describe CalendarHelper, "#calendar" do
  def base_calendar options = {}, &block
    options = { :year => Time.now.year, :month => Time.now.month}.merge options
    calendar options, &block
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
    base_calendar.should match %r{#{Date::MONTHNAMES[Time.now.month]}}
  end

  it "should render previous month text" do
    base_calendar(:previous_month_text => "PREVIOUS").should match %r{<tr>.*<td colspan="2">PREVIOUS</td>}m
  end

  it "should render next month text" do
    base_calendar(:next_month_text => "NEXT").should match %r{<tr>.*<td colspan="2">NEXT</td>}m
  end
  
  it "should render default css class names" do
    { :table_class => "calendar",
      :month_name_class => "monthName",
      :day_name_class => "dayName",
      :day_class => "day"
    }.each do |key, value|
      base_calendar(key => value).should match %r{class="#{value}"}
    end
  end
  
  it "should render custom css class names" do
    [:table_class, :month_name_class, :day_name_class, :day_class].each do |key|
      base_calendar(key => key.to_s).should match %r{class="#{key.to_s}"}
    end
  end
  
  it "should render day name abbreviations of specified length" do
    base_calendar(:abbrev => (0..2)).should match %r{>Mon<}
  end

  it "should set cell text and attrs when supplied a block" do
    calendar(:year => 2006, :month => 8) do |d|
      if d.mday % 2 == 0
        ["-#{d.mday}-", {:class => 'special_day'}]
      end
    end.should match %r{class="special_day">-2-<}
  end

  it "should default to weeks starting with Sunday" do
    base_calendar.should match %r{<tr class="dayName">.*<th scope="col">.*<abbr title="Sunday">Sun}m
  end
  
  it "should start weeks with specified day" do
    base_calendar(:first_day_of_week => 1).should match %r{<tr class="dayName">.*<th scope="col">.*<abbr title="Monday">Mon}m
  end

  it "should add css class to today by default" do
    todays_day = Date.today.day
    base_calendar.should match %r{today}
  end
  
  it "should allow css class for today to be suppressed" do
    todays_day = Date.today.day
    base_calendar(:show_today => false).should_not match %r{today}
  end
  
  it "should render valid xhtml" do
        puts base_calendar
    base_calendar.should be_valid_xhtml_fragment
  end

end


=begin
"a\nb\nc\nd".lines.map { |n| "---#{n}" }.join "\n"
date += 1 until ([2,3,4,5].include?(date.wday) && date != Date.today)
require File.expand_path(File.dirname(__FILE__) + "/../lib/calendar_helper")
class CalendarHelperTest < Test::Unit::TestCase
  
  def test_with_output
    output = []
    %w(calendar_with_defaults calendar_for_this_month calendar_with_next_and_previous).each do |methodname|
      output << "<h2>#{methodname}</h2>\n" + send(methodname.to_sym) + "\n\n"
    end
    write_sample "sample.html", output
  end
 
  # HACK Tried to use assert_select, but it's not made for free-standing
  # HTML parsing.
  def test_should_have_two_tr_tags_in_the_thead
    # TODO Use a validating service to make sure the rendered HTML is valid
    html = calendar_with_defaults
    assert_match %r{<thead>.*</thead>}, html
  end
 
  def write_sample(filename, content)
    FileUtils.mkdir_p "test/output"
    File.open("test/output/#{filename}", 'w') do |f|
      f.write %(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html><head><title>Stylesheet Tester</title><link href="../../generators/calendar_styles/templates/grey/style.css" media="screen" rel="Stylesheet" type="text/css" /></head><body>)
      f.write content
      f.write %(</body></html>)
    end
  end
 
=end

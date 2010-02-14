require 'date'
require 'nokogiri'

# CalendarHelper allows you to draw a databound calendar with fine-grained CSS formatting
module CalendarHelper

  VERSION = '0.2.2'

  # Returns an HTML calendar. In its simplest form, this method generates a plain
  # calendar (which can then be customized using CSS) for a given month and year.
  # However, this may be customized in a variety of ways -- changing the default CSS
  # classes, generating the individual day entries yourself, and so on.
  # 
  # The following options are required:
  #  :year  # The  year number to show the calendar for.
  #  :month # The month number to show the calendar for.
  # 
  # The following are optional, available for customizing the default behaviour:
  #   :table_class       => "calendar"        # The class for the <table> tag.
  #   :month_name_class  => "monthName"       # The class for the name of the month, at the top of the table.
  #   :other_month_class => "otherMonth" # Not implemented yet.
  #   :day_name_class    => "dayName"         # The class is for the names of the weekdays, at the top.
  #   :day_class         => "day"             # The class for the individual day number cells.
  #                                             This may or may not be used if you specify a block (see below).
  #   :abbrev            => (0..2)            # This option specifies how the day names should be abbreviated.
  #                                             Use (0..2) for the first three letters, (0..0) for the first, and
  #                                             (0..-1) for the entire name.
  #   :first_day_of_week => 0                 # Renders calendar starting on Sunday. Use 1 for Monday, and so on.
  #   :accessible        => true              # Turns on accessibility mode. This suffixes dates within the
  #                                           # calendar that are outside the range defined in the <caption> with 
  #                                           # <span class="hidden"> MonthName</span>
  #                                           # Defaults to false.
  #                                           # You'll need to define an appropriate style in order to make this disappear. 
  #                                           # Choose your own method of hiding content appropriately.
  #
  #   :show_today        => false             # Highlights today on the calendar using the CSS class 'today'. 
  #                                           # Defaults to true.
  #   :previous_month_text   => nil           # Displayed left of the month name if set
  #   :next_month_text   => nil               # Displayed right of the month name if set
  #   :month_header      => false             # If you use false, the current month header will disappear.
  #
  # For more customization, you can pass a code block to this method, that will get one argument, a Date object,
  # and return a values for the individual table cells. The block can return an array, [cell_text, cell_attrs],
  # cell_text being the text that is displayed and cell_attrs a hash containing the attributes for the <td> tag
  # (this can be used to change the <td>'s class for customization with CSS).
  # This block can also return the cell_text only, in which case the <td>'s class defaults to the value given in
  # +:day_class+. If the block returns nil, the default options are used.
  # 
  # Example usage:
  #   calendar(:year => 2005, :month => 6) # This generates the simplest possible calendar.
  #   calendar({:year => 2005, :month => 6, :table_class => "calendar_helper"}) # This generates a calendar, as
  #                                                                             # before, but the <table>'s class
  #                                                                             # is set to "calendar_helper".
  #   calendar(:year => 2005, :month => 6, :abbrev => (0..-1)) # This generates a simple calendar but shows the
  #                                                            # entire day name ("Sunday", "Monday", etc.) instead
  #                                                            # of only the first three letters.
  #   calendar(:year => 2005, :month => 5) do |d| # This generates a simple calendar, but gives special days
  #     if listOfSpecialDays.include?(d)          # (days that are in the array listOfSpecialDays) one CSS class,
  #       [d.mday, {:class => "specialDay"}]      # "specialDay", and gives the rest of the days another CSS class,
  #     else                                      # "normalDay". You can also use this highlight today differently
  #       [d.mday, {:class => "normalDay"}]       # from the rest of the days, etc.
  #     end
  #   end
  #
  # An additional 'weekend' class is applied to weekend days. 
  #
  # For consistency with the themes provided in the calendar_styles generator, use "specialDay" as the CSS class for marked days.
  # 
  # :output in options hash is passed to Nokogiri's to_xhtml method.  This can be used to change encoding of indentation of the output HTML
  # for example, :output => { :indent => 2 } }.  Defaults to {}, meaning the Nokogiri defaults are used.
  # see documentation on Nokogiri::XML::Node.to_xhtml at http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Node.html
  #
  def calendar(options = {}, &block)
    Calendar.new(options, &block).to_html
  end

  #  extract HTML Calendar generator into its own class
  class Calendar
    def initialize(options = {}, &block)
      raise(ArgumentError, "No year given") unless options.has_key?(:year)
      raise(ArgumentError, "No month given") unless options.has_key?(:month)
      
      defaults = {
        :table_class => 'calendar',
        :month_name_class => 'monthName',
        :other_month_class => 'otherMonth',
        :day_name_class => 'dayName',
        :day_class => 'day',
        :abbrev => (0..2),
        :first_day_of_week => 0,
        :accessible => false,
        :show_today => true,
        :previous_month_text => nil,
        :next_month_text => nil,
        :month_header => true,
        :weekend_class => 'weekend',
        :today_class => 'today',
        :output => {}
      }
      @options = defaults.merge options
      @block = block
      rails_timezone = Time.respond_to?(:zone) && Time.zone
      @today = rails_timezone ? rails_timezone.now.to_date : Date.today
    end
    
    def to_html
      builder.doc.xpath('//table').to_xhtml @options[:output]
    end
    
    private
    def builder
      Nokogiri::HTML::Builder.new do |doc|
        @doc = doc
        render_calendar
      end
    end
    
    def render_calendar
      @doc.table(:border => 0, :cellpadding => 0, :cellspacing => 0, :class => @options[:table_class]) {
        render_header
        render_body
      }
    end
    
    def render_header
      @doc.thead {
        render_month_names
        render_day_names
      }
    end

    def render_month_names
      @colspan = 7
      @doc.tr {
        render_month_navigation @options[:previous_month_text]
        render_month_name
        render_month_navigation @options[:next_month_text]
      }
    end
    
    def render_month_navigation navigation_text
      return if navigation_text.nil?
      @colspan -= 2
      @doc.td(:colspan => 2) {
        @doc.text navigation_text
      }
    end
    
    def render_month_name
      @doc.td(:class => @options[:month_name_class], :colspan => @colspan) {
        @doc.text Date::MONTHNAMES[@options[:month]]
      }
    end
    
    def render_day_names
      @doc.tr(:class => @options[:day_name_class]) {
        day_names.each do |day_name|
          render_day_name day_name
        end
      }
    end
    
    def render_day_name day_name
      abbreviated_day_name = day_name[@options[:abbrev]]

      @doc.th(:scope => 'col') {
        unless day_name.eql? abbreviated_day_name
          @doc.abbr(:title => day_name) {
            @doc.text abbreviated_day_name
          }
        else
          @doc.text day_name
        end
      }
    end
    
    def day_names
      (0..6).map { |i| Date::DAYNAMES[(i + @options[:first_day_of_week]) % 7] }
    end
    
    def render_body
      @doc.tbody {
        (calendar_start_date..calendar_end_date).each_slice(7) do |week|
          render_week week
        end
      }
    end
    
    def render_week week
      @doc.tr {
        week.each do |day|
          render_day day
        end
      }
    end
    
    def render_day day
      text, attrs = day_attrs day
      month = day.month
      
      @doc.td(attrs) {
        @doc.text text
        @doc.span(:class => 'hidden') {
          @doc.text Date::MONTHNAMES[month]
        } if @options[:accessible] && month != @options[:month]
      }
    end
    
    def calendar_start_date
      Date.civil(@options[:year], @options[:month], 1).start_of_week(@options[:first_day_of_week])
    end
    
    def calendar_end_date
      Date.civil(@options[:year], @options[:month], -1).end_of_week(@options[:first_day_of_week])
    end
    
    def day_attrs day
      text, attrs = @block.call(day) unless @block.nil?
      text ||= day.mday
      attrs ||= {}
      
      attrs.merge!( :class => [
          (attrs[:class] || @options[:day_class]),
          (@options[:other_month_class] unless day.month == @options[:month]),
          ("weekendDay" if day.weekend?),
          ("today" if (day == @today) && @options[:show_today])
        ].compact.join(' '))
      
      [text, attrs]
    end
  end
end

# add some calendar-related methods to Date class
class Date
  def start_of_week start_wday = 0
    curr_wday = self.wday
    self - curr_wday + start_wday - 
    if start_wday > curr_wday
      7
    else
      0
    end
  end
  
  def end_of_week start_wday = 0
    self.start_of_week(start_wday) + 6
  end
  
  def weekend?
    [0, 6].include? self.wday
  end
end

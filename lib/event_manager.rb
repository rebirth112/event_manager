require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def clean_phone(home_phone)
    home_phone.to_s
    if home_phone.nil?
        home_phone = "Bad Number"
    else
        home_phone.tr!('(','')
        home_phone.tr!(')', '')
        home_phone.tr!('-','')
        home_phone.tr!('.','')
        home_phone.tr!(' ','')
    end
    if home_phone.length == 11 && home_phone[0] == '1'
        home_phone = home_phone[1..-1]
    elsif home_phone.length == 11 && home_phone[0] != 1
        home_phone = "Bad Number"
    elsif home_phone.length < 10
        home_phone = "Bad Number"
    elsif home_phone.length > 11
        home_phone = "Bad Number"
    else
        home_phone = home_phone
    end
end

def search_hours(regdate)
    regdate.to_s
    new_date = DateTime.strptime(regdate, '%m/%d/%Y %H:%M')
    return new_date.hour
end

def search_days(regdate)
    regdate.to_s
    new_date = DateTime.strptime(regdate, '%m/%d/%Y %H:%M')
    wday = new_date.wday
    case wday
    when 0
        return "Sunday"
    when 1
        return "Monday"
    when 2
        return "Tuesday"
    when 3
        return "Wednesday"
    when 4
        return "Thursday"
    when 5
        return "Friday"
    when 6
        return "Saturday"
    end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  clean_phone = clean_phone(row[:homephone])
  reg_hour = search_hours(row[:regdate])
  reg_day = search_days(row[:regdate])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  puts "#{name} #{clean_phone} #{reg_hour} #{reg_day}"
  save_thank_you_letter(id,form_letter)
end

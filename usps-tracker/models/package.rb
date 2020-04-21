# frozen_string_literal: true

# Stores package information for each unique tracking number
class Package < ActiveRecord::Base
  class InvalidSubject < StandardError
  end

  class InvalidType < StandardError
  end

  class InvalidTime < StandardError
  end

  enum status: { enroute: 0, delivered: 1, ready_for_pickup: 2 }

  def self.latest_timestamp
    self.order(updated_at: :desc).first&.updated_at&.to_i
  end

  def self.upsert_with_message(message)
    subject = subject_from_message(message)

    subject_parts = subject.match(/(Item Delivered, |Expected Delivery|Ready for Pickup)([\w ,:\/]*?)(\d+$)/)

    raise InvalidSubject unless subject_parts != nil && subject_parts.length == 4

    type = subject_parts[1]
    location_or_time = subject_parts[2]
    tracking_number = subject_parts[3]

    case type
    when 'Item Delivered, '
      status = :delivered
    when 'Expected Delivery'
      status = :enroute
    when 'Ready for Pickup'
      status = :ready_for_pickup
    else
      raise InvalidType
    end

    case status
    when :enroute
      location = nil
      delivered_at = nil
      from_date, to_date = begin
        extract_times(location_or_time)
      rescue InvalidTime
        [nil, nil]
      end
    when :delivered
      location = location_or_time.strip
      delivered_at = internal_date_from_message(message)
      from_date = nil
      to_date = nil
    when :ready_for_pickup
      location = 'Pickup Location'
      delivered_at = internal_date_from_message(message)
      from_date = nil
      to_date = nil
    end

    package = self.find_or_create_by(tracking_number: tracking_number)
    package.update!(
      status: status,
      latest_message_subject: subject,
      tracking_number: tracking_number,
      delivered_location: location,
      delivery_from: from_date,
      delivery_to: to_date,
      delivered_at: delivered_at
    )
    package
  end

  private_class_method def self.extract_times(text)
    day_regex_string = Date::DAYNAMES.map do |day_name|
      "#{day_name.downcase},|"
    end.join('')
    day_regex = Regexp.new(day_regex_string)

    text = text.downcase.gsub(/^ by/, '').gsub(/^ on/, '').gsub(day_regex, '').squeeze(' ')

    if text.include?('between')
      date_parts = text.split(' between ')
      date = date_parts[0]
      time_parts = date_parts[1].split(' and ')

      from_string = "#{date} #{time_parts[0]}"
      to_string = "#{date} #{time_parts[1]}"

      from_date = Chronic.parse(from_string)
      to_date = Chronic.parse(to_string)
    elsif text.include?('arriving by')
      date_parts = text.split(' arriving by ')
      date = date_parts[0]
      time = date_parts[1]

      from_date = nil
      to_date = Chronic.parse("#{date} #{time}")
    else
      raise InvalidTime
    end

    [from_date, to_date]
  end

  private_class_method def self.internal_date_from_message(message)
    Time.at(message.internal_date.to_s[0..9].to_i)
  end

  private_class_method def self.subject_from_message(message)
    message.payload.headers.find { |h| h.name == 'Subject' }.value
  end
end

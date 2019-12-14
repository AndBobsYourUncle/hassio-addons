json.packages do
  json.array! @packages do |package|
    json.(package, :status, :latest_message_subject, :tracking_number, :delivered_location, :delivery_from, :delivery_to, :delivered_at)
  end
end

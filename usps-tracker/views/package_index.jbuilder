json.packages do
  json.array! @packages do |package|
    json.(package, :status, :tracking_number, :delivered_location, :delivery_from, :delivery_to)
  end
end

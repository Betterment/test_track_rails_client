json.visitor do
  json.partial!('tt/api/v1/visitors/show', visitor: @visitor)
end

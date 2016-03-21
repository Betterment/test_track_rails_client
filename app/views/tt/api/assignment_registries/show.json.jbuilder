@assignments.each do |assignment|
  json.set! assignment.split_name, split.variant
end

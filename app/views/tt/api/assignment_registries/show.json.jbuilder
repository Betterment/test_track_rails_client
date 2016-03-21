@assignments.each do |assignment|
  json.set! assignment.split_name, assignment.variant
end

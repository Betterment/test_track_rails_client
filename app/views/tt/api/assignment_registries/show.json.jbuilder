@assignments.each do |assignment|
  json.set! assignment.name, assignment.sample_variant
end

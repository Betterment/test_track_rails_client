@splits.each do |split|
  json.set! split.name, split.sample_variant
end

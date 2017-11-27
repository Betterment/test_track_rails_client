module RailsCompatibilitySpecHelper
  %i(get post put delete).each do |method_name|
    define_method method_name do |action, params = {}, session = {}, flash = {}|
      if Rails::VERSION::MAJOR >= 5
        super(action, params: params, session: session, flash: flash)
      else
        super(action, params, session, flash)
      end
    end
  end
end

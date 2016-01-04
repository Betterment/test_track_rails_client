# test_track_rails_client
Rails client for the test_track service

## Installation

Install the gem:

```ruby
# Gemfile

gem 'test_track_rails_client', git: 'https://[GITHUB AUTH CREDS GO HERE]@github.com/Betterment/test_track_rails_client'
```

Cut an App record via the TestTrack rails console:

```ruby
> App.create!(name: "[myapp]", auth_secret: SecureRandom.urlsafe_base64(32)).auth_secret
=> "[your new app password]"
```

Set up ENV vars:

* `MIXPANEL_TOKEN` - Set this to your mixpanel key
* `TEST_TRACK_API_URL` - Set this to the URL of your TestTrack instance with your app credentials, e.g. `http://[myapp]:[your new app password]@testtrack.dev/`

Mix `TestTrack::Controller` into any controllers needing access to TestTrack:

```ruby
class MyController < ApplicationController
  include TestTrack::Controller
end
```

# Concepts

* **Visitor** - a person using your application.  `test_track_rails_client` manages visitors for you and ensures that `test_track_visitor` is available in any controller that mixes in `TestTrack::Controller`
* **Split** - A feature for which TestTrack will be assigning different behavior for different visitors.  Split names must be strings and should be expressed in `snake_case`. E.g. `homepage_redesign_late_2015` or `signup_button_color`.
* **Variant** - one the values that a given visitor will be assigned for a split, e.g. `true` or `false` for a classic A/B test or e.g. `red`, `blue`, and `green` for a multi-way split.  Variants may be strings or booleans, and they should be expressed in `snake_case`.
* **Weighting** - Variants are assigned pseudo-randomly to visitors based on their visitor IDs and the weightings for the variants.  Weightings describe the probability of a visitor being assigned to a given variant in integer percentages.  All the variant weightings for a given split must sum to 100, though variants may have a weighting of 0.
* **IdentifierType** - A name for a customer identifier that is meaningful in your application, typically things that people sign up as, log in as.  They should be expressed in `snake_case` and conventionally are prefixed with the application name that the identifier is for, e.g. `myapp_user_id`, `myapp_lead_id`.

## Configuring the TestTrack server from your app

TestTrack leans on ActiveRecord migrations to run idempotent configuration changes.  There are two things an app can configure about TestTrack.  It can define `identifier_type`s and configure `split`s.

### Defining identifier types:

```ruby
class AddIdentifierType < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.identifier_type :myapp_user_id
    end
  end
end
```

### Configuring splits

Splits can be created or reconfigured using the config DSL.  Variants can be added to an existing split, and weightings can be reassigned, but note that once a variant is added to a split, it doesn't ever completely disappear.  Attempts to remove it will simply result in it having a `0` weighting moving forward.  People who were already assigned to a given variant will continue to see the experience associated with that split.

```ruby
class ConfigureMySplit < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.split :signup_button_color, red: 34, green: 33, blue: 33, indigo: 0
    end
  end
end
```

### Finishing splits

In order to avoid clutter in the Test Track server's split registry as well as the Test Track Chrome Extension, a split can be finished. This will remove the split from the Test Track clients' perspective and should therefore only be done once there are no longer any code paths referencing that split.

```ruby
class FinishMySplit < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.finish_split :signup_button_color
    end
  end
end
```

## Varying app behavior based on assigned variant

The `test_track_visitor`, which is accessible from all controllers and views that mix in `TestTrack::Controller` provides a `vary` DSL.

You must provide at least one call to `when` and only one call to `default`. `when` can take multiple variant names if you'd like to map multiple variants to one user experience.

If the user is assigned to a variant that is not represented in your vary configuration, Test Track will execute the `default` handler and re-assign the user to the variant specified in the `default` call. You should not rely on this defaulting behavior, it is merely provided to ensure we don't break the customer experience. You should instead make sure that you represent all variants of the split and if variants are added to the split on the backend, update your code to reflect the new variants. Because `default` re-assigns the user to the default variant, no data will be recorded for the variant that is not represented. This will impede our abiltiy to collect meaningful data for the split.

```ruby
test_track_visitor.vary :name_of_split do |v|
  v.when :variant_1, :variant_2 do
    # Do something
  end
  v.when :variant_3 do
    # Do another thing
  end
  v.default :variant_4 do
    # Do something else
  end
end
```

The `test_track_visitor`'s `ab` method provides a convenient way to do two-way splits. The optional second argument is used to tell `ab` which variant is the "true" variant. If no second argument is provided, the "true" variant is assumed to be `true`, which is convient for splits that have variants of `true` and `false`. `ab` can be easily used in an if statement.

```ruby
# "button_color" split with "blue" and "red" variants
if test_track_visitor.ab :button_color, :blue
  # Color the button blue
else
  # Color the button red
end
```

```ruby
# "dark_deployed_feature" split with "true" and "false" variants
if test_track_visitor.ab :dark_deployed_feature
  # Show the dark deployed feature
end
```

## Tracking visitor logins

The `test_track_visitor.log_in!` is used to ensure a consistent experience across devices. For instance, when a user logs in to your app on their mobile device we can log in to Test Track in order to grab their existing split assignments instead of treating them like a new visitor.

```ruby
test_track_visitor.log_in!(:myapp_user_id, 1234)
```

## Tracking signups

The `test_track_visitor.sign_up!` method tells TestTrack when a new identifier has been created and assigned to a visitor.  It works a lot like the `log_in!` method, but should only be used once per customer signup.

```ruby
test_track_visitor.sign_up!(:myapp_user_id, 2345)
```

## Testing splits

Add this line to your `rails_helper.rb`:

```ruby
# spec/rails_helper.rb
require 'test_track_rails_client/rspec_helpers'
```

Force TestTrack to return a specific set of splits during a block:

```ruby
it "shows the right info" do
  with_test_track_assignments(button_color: :red) do
    # All `vary` calls for `button_color` will  run the `red` codepath until the end of this block
  end
end
```

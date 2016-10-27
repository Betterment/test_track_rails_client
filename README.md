# TestTrack Rails Client

[![Build Status](https://travis-ci.org/Betterment/test_track_rails_client.svg?branch=master)](https://travis-ci.com/Betterment/test_track_rails_client)

This is the Rails client library for the [TestTrack](https://github.com/Betterment/test_track) system.

It provides server-side split-testing and feature-toggling through a simple API.

If you're looking to do client-side assignment, then check out our [JS client](https://github.com/Betterment/test_track_js_client).

## Installation

Install the gem:

```ruby
# Gemfile
gem 'test_track_rails_client'
```

In every environment (local included) cut an App record via the **TestTrack server** rails console:

```ruby
> App.create!(name: "[myapp]", auth_secret: SecureRandom.urlsafe_base64(32)).auth_secret
=> "[your new app password]"
```

*Note: [see the TestTrack
README](https://github.com/Betterment/test_track/blob/master/README.md#user-content-seeding-apps-for-local-development)*
for additional information on configuring seed apps for local
development.

Set up ENV vars in every environment:

* `MIXPANEL_TOKEN` - By default, TestTrack reports to Mixpanel. If you're using a [custom analytics provider](#custom-analytics) you can omit this.
* `TEST_TRACK_API_URL` - Set this to the URL of your TestTrack instance with your app credentials, e.g. `http://[myapp]:[your new app password]@testtrack.dev/`

Mix `TestTrack::Controller` into any controllers needing access to TestTrack:

```ruby
class MyController < ApplicationController
  include TestTrack::Controller
end
```

If you'd like to be able to use the [TestTrack Chrome Extension](https://github.com/Betterment/test_track_chrome_extension) which makes it easy for you and your team to change assignments via your browser, you **must** set up the TestTrack JS client.

1. `testTrack.bundle.min` in your `application.js` file after your reference to jQuery

  ```js
  //= require jquery
  //= require testTrack.bundle.min
  ```

1. Then, follow the instructions for [configuring the JS client](https://github.com/Betterment/test_track_js_client#configuration).

## Concepts

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

### Cleaning Up Old Splits

In order to avoid clutter in the Test Track server's split registry as well as the Test Track Chrome Extension, a split can be dropped. This will remove the split from the split registry, dropping it from Test Track clients' perspectives. Thus, like a non-additive DDL migration (e.g. `DROP COLUMN`, `RENAME COLUMN`), it should be released in a subsequent deployment, after all code paths referencing the split have been removed. Otherwise those code paths will raise and potentially break the user experience.

```ruby
class RemoveMyOldSplit < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.drop_split :signup_button_color
    end
  end
end
```

_Note: `drop_split` (a.k.a. `finish_split`) does not physically delete split data from mixpanel or Test Track's database._

## Varying app behavior based on assigned variant

### Varying app behavior in a web context

The `test_track_visitor`, which is accessible from all controllers and views that mix in `TestTrack::Controller` provides a `vary` DSL.

You must provide at least one call to `when` and only one call to `default`. `when` can take multiple variant names if you'd like to map multiple variants to one user experience.

If the user is assigned to a variant that is not represented in your vary configuration, Test Track will execute the `default` handler and re-assign the user to the variant specified in the `default` call. You should not rely on this defaulting behavior, it is merely provided to ensure we don't break the customer experience. You should instead make sure that you represent all variants of the split and if variants are added to the split on the backend, update your code to reflect the new variants. Because `default` re-assigns the user to the default variant, no data will be recorded for the variant that is not represented. This will impede our abiltiy to collect meaningful data for the split.

You must also provide a `context` at each `vary` and `ab` call. Context is a string value which represents the high-level user action in which the assignment takes place. For example, if a split can be assigned when viewing the home page and when going through sign up, the assignment calls in each of those paths should tagged with 'home_page' and 'signup' respectively. This will allow the test results to be filtered by what the user was doing when the split was assigned.

```ruby
test_track_visitor.vary :name_of_split, context: 'home_page' do |v|
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
if test_track_visitor.ab :button_color, true_variant: :blue, context: 'signup'
  # Color the button blue
else
  # Color the button red
end
```

```ruby
# "dark_deployed_feature" split with "true" and "false" variants
if test_track_visitor.ab :dark_deployed_feature, context: 'signup'
  # Show the dark deployed feature
end
```

### Varying app behavior in an offline context

The `OfflineSession` class can be used to load a test track visitor when there is no access to browser cookies. It is perfect for use in a process being run from either a job queue or a scheduler. The visitor object that is yielded to the block is the same as the visitor in a controller context; it has both the `vary` and `ab` methods.

```ruby
OfflineSession.with_visitor_for(:myapp_user_id, 1234) do |test_track_visitor|
  test_track_visitor.vary :name_of_split, context: 'background_job' do |v|
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
end
```

### Varying app behavior from within a model

The `TestTrack::Identity` concern can be included in a model and it will add two methods to the model: `test_track_vary` and `test_track_ab`. Behind the scenes, these methods check to see if they are being used within a web context of a controller that includes `TestTrack::Controller` or not. If called in a web context they will use the `test_track_visitor` that the controller has and participate in the existing session, if not, they will standup an `OfflineSession`.

Because these methods may need to stand up an `OfflineSession` the consuming model needs to provide both the identifier type and which column should be used as the identifier value via the `test_track_identifier` method so that the `OfflineSession` can grab the correct visitor.

```ruby
class User
  include TestTrack::Identity

  test_track_identifier :myapp_user_id, :id # `id` is a column on User model which is what we're using as the identifier value in this example.
end
```

N.B. If you call `test_track_vary` and `test_track_ab` on a model in a web context, but that model is not the currently authenticated model, an `OfflineSession` will be created instead of participating in the existing session.

## Tracking visitor logins

The `test_track_visitor.log_in!` is used to ensure a consistent experience across devices. For instance, when a user logs in to your app on their mobile device we can log in to Test Track in order to grab their existing split assignments instead of treating them like a new visitor.

```ruby
test_track_visitor.log_in!(:myapp_user_id, 1234)
```

When we call `log_in!` we merge assignments between the visitor prior to login (i.e. the current visitor) and the visitor we retrieve from the test track server (i.e. the canonical visitor). This means that any assignments for splits that the current visitor has which the canonical visitor does not have are copied from the prior visitor to the canonical visitor. While this merging behavior is preferrable there may be a case where we do not want to merge. In that case, we can pass the `forget_current_visitor` option to forget the current visitor before retrieving the canonical visitor.

```ruby
test_track_visitor.log_in!(:myapp_user_id, 1234, forget_current_visitor: true)
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

Force TestTrack to return a specific set of splits during a spec:

```ruby
it "shows the right info" do
  stub_test_track_assignments(button_color: :red)
  # All `vary` calls for `button_color` will  run the `red` codepath until the mocks are reset (after each `it` block)
end
```

## Custom Analytics
By default, TestTrack will use Mixpanel as an analytics backend. If you wish to use another provider, you can set the `analytics` attribute on `TestTrack` with your custom client. You should do this in a Rails initializer.

```ruby
# config/initializers/test_track.rb
TestTrack.analytics = MyCustomAnalyticsClient.new
```

Your client must implement the following methods:

```ruby
# Called when a new Split has been Assigned
#
# @param visitor_id [String] TestTrack's unique visitor identification key
# @param assignment [TestTrack::Assignment] The assignment model itself
# @param properties [String] Any additional properties, currently only utilized for Mixpanel's UniqueId
def track_assignment(visitor_id, assignment, properties)

# Called after TestTrack.sign_up!
#
# @param visitor_id [String] TestTrack's unique visitor identification key
# @param existing_id [String] Any existing identifier for the visitor(defaults to Mixpanel's UniqueId)
def alias(visitor_id, existing_id)
```

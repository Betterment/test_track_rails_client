# TestTrack Rails Client

[![Build Status](https://travis-ci.org/Betterment/test_track_rails_client.svg?branch=master)](https://travis-ci.org/Betterment/test_track_rails_client)

This is the Rails client library for the [TestTrack](https://github.com/Betterment/test_track) system.

It provides server-side split-testing and feature-toggling through a simple API.

If you're looking to do client-side assignment, then check out our [JS client](https://github.com/Betterment/test_track_js_client).

* [Installation](#installation)
* [Concepts](#concepts)
* [Configuring the TestTrack server from your app](#configuring-the-testtrack-server-from-your-app)
* [Varying app behavior based on assigned variant](#varying-app-behavior-based-on-assigned-variant)
* [Tracking visitor logins](#tracking-visitor-logins)
* [Tracking signups](#tracking-signups)
* [Testing splits](#testing-splits)
* [Analytics](#analytics)
* [Upgrading](#upgrading)
* [How to Contribute](#how-to-contribute)

## Installation

### Install the gem:

```ruby
# Gemfile
gem 'test_track_rails_client'
```

### Create an app in the TestTrack server

In every environment (local included) cut an App record via the **TestTrack server** rails console:

```ruby
> App.create!(name: "[myapp]", auth_secret: SecureRandom.urlsafe_base64(32)).auth_secret
=> "[your new app password]"
```

*Note: [see the TestTrack
README](https://github.com/Betterment/test_track/blob/master/README.md#user-content-seeding-apps-for-local-development)*
for additional information on configuring seed apps for local
development.

### Set up ENV vars

Set up ENV vars in every environment:

* `MIXPANEL_TOKEN` - By default, TestTrack reports to Mixpanel. If you're using a [custom analytics provider](#analytics) you can omit this.
* `TEST_TRACK_API_URL` - Set this to the URL of your TestTrack instance with your app credentials, e.g. `http://[myapp]:[your new app password]@[your-app-domain]/`

  [your-app-domain] can be
  * `testtrack.dev` ([Pow](pow.cx))
  * `localhost:PORT`
  * `example.org`
  * etc

### Prepare your controllers

Mix `TestTrack::Controller` into any controllers needing access to TestTrack and configure it with the name of your `:current_user` method.

```ruby
class MyController < ApplicationController
  include TestTrack::Controller

  self.test_track_identity = :current_user
end
```

If your app doesn't support authentication, set
`self.test_track_identity` to `:none`.

### Prepare your identity models (optional)

If your app supports authentication, You'll need to configure your
`User` model as a [TestTrack Identity](#varying-app-behavior-from-within-a-model)

### Set up the Chrome extension (optional)

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

### Generating Split Migrations

Split configuration changes can be generated using Rails generators that are included with the TestTrack Rails client.

```
rails generate test_track:migration add_name_of_split
```

will generate a timestamped migration file with the content

```ruby
class AddNameOfSplit < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.split :name_of_split, control: 50, treatment: 50
    end
  end
end
```

The generator infers the type of split from the migration name.

Adding `Drop` to the migration name will create a migration to drop a split.

```
rails generate test_track:migration drop_name_of_split
```

```ruby
class DropNameOfSplit < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.drop_split :name_of_split
    end
  end
end
```

Adding `Enabled` or `FeatureFlag` to the end of the migration name will create sensible defaults for a feature flag split.

```
rails generate test_track:migration add_name_of_split_enabled
```

```ruby
class AddNameOfSplitEnabled < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.split :name_of_split_enabled, true: 0, false: 100
    end
  end
end
```

Adding `Experiment` to the end of the migration name will create sensible defaults for an experiment.

```
rails generate test_track:migration add_name_of_split_experiment
```

```ruby
class AddNameOfSplitExperiment < ActiveRecord::Migration
  def change
    TestTrack.update_config do |c|
      c.split :name_of_split_experiment, control: 50, treatment: 50
    end
  end
end
```

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

The `test_track_visitor`'s `ab` method provides a convenient way to do two-way splits. The `true_variant` option is used to tell `ab` which variant is the "true" variant. If no `true_variant` option is provided, the "true" variant is assumed to be `true`, which is convenient for splits that have variants of `true` and `false`. `ab` can be easily used in an if statement.

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

### Varying app behavior from within a model

The `TestTrack::Identity` concern can be included in a model and it will add two methods to the model: `test_track_vary` and `test_track_ab`.

```ruby
class User
  include TestTrack::Identity

  test_track_identifier :myapp_user_id, :id # `id` is a column on User model which is what we're using as the identifier value in this example.
end
```
### Varying app behavior globally

The `TestTrack.app_ab` method uses an "app" identifier type to be able to globally access "Feature Gate" splits. This is useful when a visitor context is not handy, and when you don't care about visitor specific assignments.

In order to use this feature, you need to set `TestTrack.app_name`, preferably in an app initializer.

```ruby
# config/initializers/test_track.rb
TestTrack.app_name = "MyApp"
```

```ruby
class BackgroundWorkJob
  def perform
    if TestTrack.app_ab(:fancy_new_api_enabled, context: 'BackgroundWorkJob')
      FancyNewApi.do_thing
    else
      CruftyOldApi.do_thing
    end
  end
end
``` 

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

## Testing your split-dependent application code with RSpec

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

## Analytics

TestTrack does not offer built-in functionality for analyzing the results of split tests. TestTrack does provide hooks to easily integrate with your preferred analytics tool. By default, TestTrack will use Mixpanel as an analytics backend. If you wish to use another tool, you can set the `analytics` attribute on `TestTrack` with your custom client. You should do this in a Rails initializer.

```ruby
# config/initializers/test_track.rb
TestTrack.analytics_class_name = 'MyCustomAnalyticsClient'
```

Your client must be a singleton or requre no initializer arguments, implement the following methods:

```ruby
# Called when a new Split has been Assigned
#
# @param analytics_event [TestTrack::AnalyticsEvent] An object
# representing an analytics event providing name and properties
# values you can send to your analytics backend
def track(analytics_event)

# Called after TestTrack.sign_up!
#
# @param visitor_id [String] TestTrack's unique visitor identification key
def sign_up!(visitor_id)
```

### Using TestTrack with a new analytics tool

TestTrack manages its own visitor identifier which is different from the identifier of your analytics tool. We recommend using TestTrack's visitor identifier as your analytics identifier when possible. Within TestTrack Rails Client, assignment events will trigger a call to `TestTrack.analytics.track` with a TestTrack visitor identifier. To ensure that analytics events coming from within the browser have the right identifier, you must set the identifier when your analytics javascript library is loaded.

Here's an example for how to do it with Mixpanel:

```javascript
mixpanel.init('YOUR MIXPANEL TOKEN', {
    loaded: function(mixpanel) {
        mixpanel.identify('<%= test_track_visitor.id %>');
    }
});
```

## Misconfiguration notifications

TestTrack provides hooks to easily integrate with your preferred error catching tool to receive notifications when we detect a misconfiguration in split usage. TestTrack has built-in support for `Airbrake`. By default, if you've included the `airbrake` gem, TestTrack will use `Airbrake` as a misconfiguration notifier backend. If you wish to use another tool, you can set the `misconfiguration_notifier` attribute on `TestTrack` with your custom client. You should do this in a Rails initializer.

```ruby
# config/initializers/test_track.rb
TestTrack.misconfiguration_notifier_class_name = 'MyCustomMisconfigurationNotifier'
```

Your client must be a singleton or requre no initializer arguments, implement the following methods:

```ruby
# Called when a Split misconfiguration is detected
#
# @param string message describing the misconfiguration
def notify(message)
```

## Upgrading

### From 3.0 to 4.0

The contract of custom analytics plugins has changed. Instead of
implementing `track_assignment` you now must implement `track`. It's
easier and more conventional, though, and takes care of differentiating
between expiriment assignments and feature gate experiences, which are
no longer recorded server-side.

You also must add `self.test_track_identity = :current_user` (or
whatever your controller uses as a sign-in identity) to your
TestTrack-enabled controllers, or set it to `:none` if your app doesn't
support authentication.

If your app supports authentication, You'll need to configure your
user model as a [TestTrack Identity](#varying-app-behavior-from-within-a-model)

### From 2.0 to 3.0

TestTrack Rails Client no longer manages your Mixpanel cookie. The analytics plugin now provides a callback on `sign_up!` that will allow you to implement this functionality within your application. Please see the [analytics documentation](#analytics) for more details.
The TestTrack.analytics client `#track_assignment` method no longer accepts a properties hash as an argument as `mixpanel_distinct_id` is no longer relevant.

### From 1.x to 1.3

`TestTrack::Session#log_in!` and `TestTrack:Session#sign_up!` now take a `TestTrack::Identity` instance argument instead of an identity type and identity value.

## How to Contribute

We would love for you to contribute! Anything that benefits the majority of `test_track` users—from a documentation fix to an entirely new feature—is encouraged.

Before diving in, [check our issue tracker](//github.com/Betterment/test_track_rails_client/issues) and consider creating a new issue to get early feedback on your proposed change.

### Suggested Workflow

* Fork the project and create a new branch for your contribution.
* Write your contribution (and any applicable test coverage).
* Make sure all tests pass (`bundle exec rake`).
* Submit a pull request.

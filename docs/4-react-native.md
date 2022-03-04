## Part 4: Adding in React Native

In this example, we are effectively going to demonstrate how to setup a basic React Native app that can support the cookie-based session storage or our Rails application.

It expects that you have some experience with setting up a [React Native app](https://reactnative.dev/docs/environment-setup).

We are going to create the react native repo in another application.

```s
# Create app in `mobile` folder for demo purposes - this may normally be another repo altogether
$ npx react-native init DemoReactNativeRailsAuth --template @native-base/react-native-template-typescript
$ cd DemoReactNativeRailsAuth
$ npx react-native start

# In another tab to start the iOS simulator
$ npx react-native ios
```

To enable us to use session cookies for API auth in the React Native app, we can follow a similar path to a [blog post](https://pragmaticstudio.com/tutorials/rails-session-cookies-for-api-authentication) written by Pragmatic Studio.

To setup our Rails setup to pass the CSRF cookie as a token, let's update our Rails application controller at `app/controllers/application_controller.rb`:

```rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_csrf_cookie

  private

  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = form_authenticity_token
  end
end
```

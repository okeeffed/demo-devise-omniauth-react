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

Notes:

Add `rack-cors` gem.

Start up the app with `bin/dev`.

In another terminal, you can see what is happening with `redis-cli monitor`.

You will get something like this:

```s
$ redis-cli monitor
OK
1646385148.623807 [0 [::1]:49436] "get" "session:2::69618aacfcd4737514bd0d540b73ccc2020b5f98a192c2baa38fda2c7618f8e0"
1646385148.880797 [0 [::1]:49436] "del" "session:2612c5dbfddbd05a599133f36b8aef68"
1646385148.883186 [0 [::1]:49436] "del" "session:2::69618aacfcd4737514bd0d540b73ccc2020b5f98a192c2baa38fda2c7618f8e0"
1646385148.884397 [0 [::1]:49436] "setex" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb" "5400" "\x04\b{\aI\"\x19warden.user.user.key\x06:\x06ET[\a[\x06i\x06I\"\"$2a$12$OVcvnckKRbDKK5UEPZubl.\x06;\x00TI\"\nflash\x06;\x00T{\aI\"\x0cdiscard\x06;\x00T[\x00I\"\x0cflashes\x06;\x00T{\x06I\"\x0bnotice\x06;\x00FI\"\x1cSigned in successfully.\x06;\x00T"
1646385148.905098 [0 [::1]:49436] "get" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb"
1646385148.920525 [0 [::1]:49436] "setex" "session:2::ecb8e65b0cdda7092604b3b3b66873202cec32d1ca1af8f589eddfde63022cdb" "5400" "\x04\b{\bI\"\x19warden.user.user.key\x06:\x06ET[\a[\x06i\x06I\"\"$2a$12$OVcvnckKRbDKK5UEPZubl.\x06;\x00TI\"\nflash\x06;\x00T{\aI\"\x0cdiscard\x06;\x00T[\x00I\"\x0cflashes\x06;\x00T{\x06I\"\x0bnotice\x06;\x00FI\"\x1cSigned in successfully.\x06;\x00TI\"\x10_csrf_token\x06;\x00FI\"0vS4dc826i_YDuGX6PGKHyHCLQp7fsUw_KiXsMByvdMs\x06;\x00F"
```

If you reload the page you will still be signed in and you'll notice more requests are made to the `redis-cli monitor` terminal.

One of the benefits of Redis session storage is that you have full control over the session. If you run `redis-cli flushdb` in another terminal and then reload the page, you'll notice that the session has been removed and you'll be redirected to log in once again.

## Part 4: Custom styles on the home page

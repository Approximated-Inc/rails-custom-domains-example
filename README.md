# Rails Custom Domains Example

This is an example repo to help you understand how you could implement custom domains easily as a feature
in your Rails application using [Approximated](https://approximated.app).


## How it works

The core unit of this application is a Page model. It consists of a title, a simple textual content, and a custom
domain. The application provides a simple user interface to manage these Pages, syncs the changes to Approximated
and displays the Page on the specified custom domain.

When a Page with a custom domain is created, the application will create a virtual host in Approximated and provide
instructions to set a DNS record for the domain. When a Page is changed, it'll update the virtual host and when
it's destroyed, it'll delete the virtual host.

The flow of an incoming request is as follows:
- The request hits the router.
- The router checks if the requested domain matches the application primary domain specified as an env variable
  `APP_PRIMARY_DOMAIN`.
- If the requested domain matches the application domain, it routes the request to the `PagesController`
  and shows the management of Pages.
- If it doesn't match the application domain, it routes the request to the `PublicPagesController`.
- The `PublicPagesController` tries to find a Page with the requested custom domain based on either
  the request header `apx-incoming-host` or the request host.
- If a Page with this custom domain is found, it'll render the public site for the Page.
- If the requested domain doesn't match a custom domain in the database or the primary domain, it shows 404.


## Files to check out

- [config/routes.rb](config/routes.rb) -
  Rails routing for the main application and public pages with custom domains.
- [app/constraints/app_domain_constraint.rb](app/constraints/app_domain_constraint.rb) - 
  Route constraint to differentiate between primary domain and custom domains.
- [app/controllers/pages_controller.rb](app/controllers/pages_controller.rb) -
  Controller for managing pages.
- [app/controllers/public_pages_controller.rb](app/controllers/public_pages_controller.rb) -
  Controller handling custom domains.
- [app/models/page.rb](app/models/page.rb) -
  Page model with callbacks managing Approximated virtual hosts.
- [app/services/approximated.rb](app/services/approximated.rb) -
  Service for talking to the Approximated API.
- [app/views/layouts/application.html.erb](app/views/layouts/application.html.erb) -
  View layout for main application.
- [app/views/layouts/public.html.erb](app/views/layouts/public.html.erb) -
  View layout for public pages on custom domains.


## Trying it out

1. Copy the `.env.example` file to `.env`.
2. Set the `APP_PRIMARY_DOMAIN` in `.env` to your local dev domain (e.g. `localhost`).
3. Set the `APPROXIMATED_API_KEY` in `.env` to your API key from the Approximated dashboard.
4. Run `bundle install`, `bin/rails db:setup` and `bin/dev` from the project root folder.
5. Open the application in your browser and create a Page. Fill in your local domain
   (e.g. `localhost`) as a custom domain.
6. To test the custom domain in a local environment, change the `APP_PRIMARY_DOMAIN` in the `.env` file
   to anything else temporarily. This makes the router not match your local domain as the primary domain,
   so it'll handle it as a custom domain. 
7. Restart the web server and reload the page. You should see a public site for your Page. 
8. To get back to the main app dashboard again, just change the `APP_PRIMARY_DOMAIN` back.


## Assets and CORS

These work out of the box in this example app, because their paths are relative. If your app is linking
to assets with absolute URLs, changing them to relative paths should fix any CORS issues.

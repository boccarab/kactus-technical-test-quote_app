## About

Basic quote application. 2 pages
- Quote listing
- Quote editor

## Technical stack

- Framework Ruby on Rails 8.1
- Use Stimulus/Hotwire for reactivity. No JS Framework.
- DB Postgresql
- CSS Tailwind. Use tailwindcss-rails (official gem, Tailwind v4, config CSS-first via @theme dans application.tailwind.css, no tailwind.config.js)
- No authentication
- Don't install any gem if not asked

## Do

- Always sanitize incoming parameters using strong_parameters
- Don't repeat yourself in controller, use before_filter to retrieve the current object.
- Use underscores as three-digit thousands separators

## Don't

- Don't run rubocop to validate formatting. I'll do it

## Testing

- Don't add fixtures

## UI

Main colors:
- Primary color: #201542
- Secondary color: #FCDB3E
- Danger: #F3682B

Use tailwind's table utilities https://tailwindcss.com/docs/display#table instead of <table> html tags 

### Notifications

- Every action that returns a `notice` or `alert` must display it through the global toaster.
- For redirects, set the flash using `notice:` or `alert:` so the application layout renders it.
- For Turbo Stream responses without a redirect, set `flash.now[:notice]` or `flash.now[:alert]` and include `turbo_stream.update("toaster", partial: "shared/toaster")` in the response.

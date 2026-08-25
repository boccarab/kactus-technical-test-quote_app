# Kactus Quote App

A small quote-management application built with Ruby on Rails. It lets you create and edit quotes with line items, calculate totals and VAT, and move quotes through draft, published, and archived states.

## Requirements

- Ruby 3.4.10
- PostgreSQL
- Node.js and Yarn

The application uses Rails 8.1, Hotwire/Stimulus, Tailwind CSS 4, and PostgreSQL.

By default, PostgreSQL is expected at `localhost:5432`. You can override these values with `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, and `DATABASE_PASSWORD` env var.

## Initialize the application

Clone the repository, enter its directory, make sure PostgreSQL is running, then run:

```sh
bin/setup --skip-server
```

This installs the Ruby and JavaScript dependencies, creates the databases, and runs the migrations.

## Seed the development database

```sh
bin/rails db:seed
```

The seed task replaces the existing development quotes with 10 sample quotes containing 30 line items. It is intentionally restricted to the development environment.

To recreate the database and load the seeds in one command:

```sh
bin/rails db:reset
```

## Launch the application

```sh
bin/dev
```

This starts Rails along with the JavaScript and Tailwind CSS watchers. Open [http://localhost:3000](http://localhost:3000) in your browser.

You can also initialize and launch the application directly with:

```sh
bin/setup
```

## Run the tests

```sh
bin/rails test
```

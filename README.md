# Rebuilder

Generates Pull Requests in [everypolitician/everypolitician-data](https://github.com/everypolitician/everypolitician-data) by rebuilding a specific legislatures data from source. Scrapers can ping this app after they've run to update the data in EveryPolitician.

## Usage

    POST /

### Parameters

Name | Type | Description
-----|------|--------------
`country`|`string` | **Required**. The slug from `countries.json` of the country to rebuild
`legislature`|`string` | **Required**. The slug from `countries.json` of the legislature to rebuild
`source`|`string` | The specific source to rebuild.

## Development

### Install

Clone this repository

    git clone https://github.com/everypolitician/rebuilder
    cd rebuilder

Install dependencies

    bundle install

### Usage

Run the app server

    foreman start

You can then trigger a rebuild using `curl(1)`:

    curl -i -X POST -d 'country=Australia' -d 'legislature=Senate' http://localhost:5000/

## Architecture

### Running external commands

The main task this app performs is running the EveryPolitician build process as an external command and then creating a pull request with the output from the command. As such, one of the main classes in the system is the `ExternalCommand` class. This encapsulates running an external command, checking for errors and returning the output.

To use this class create an instance of `ExternalCommand` and pass `command` and `env` keyword arguments to the constructor. The `command` should be a string representing the external command to execute, and `env` is an optional hash containing environment variables that should be set, or if they are `nil`, unset.

Note that a given instance will only run an external command once. Create a new instance if you need to run the command again.

```ruby
command = ExternalCommand.new(
  command: 'echo "Hello, $name."',
  env: { 'name' => 'Bob' }
).run

# Now you can access the output and status of the command.
command.output # => "Hello, Bob.\n"
command.success? # => true
```

### Cleaning the output from external commands

The output of external commands is included in the resulting pull request that the Rebuilder creates. Before including it in a pull request the output needs to be cleaned to remove any API keysand strip color escape codes. Use the `CleanedOutput` class to obtain a cleaned version of an external command's output.

```ruby
cleaned_output = CleanedOutput.new(output: 'API Key: Test', morph_api_key: 'Test')
puts cleaned_output.to_s # => "API Key: REDACTED"
```

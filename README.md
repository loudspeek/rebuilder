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

### Cleaning the output from external commands

The output of external commands is included in the resulting pull request that the Rebuilder creates. Before including it in a pull request the output needs to be cleaned up. We currently apply the following transforms:

- Apply a set of redactions to protect API keys etc
- Strip color escape codes from the output
- Return only the last n characters of the body (default 64,000, for using in GitHub comments)

Use the `CleanedOutput` class to obtain a cleaned version of an external command's output.

```ruby
cleaned_output = CleanedOutput.new(output: 'key=secret pw=password', redactions: ['secret', 'password'])
puts cleaned_output.to_s # => "key=REDACTED pw=REDACTED"
```

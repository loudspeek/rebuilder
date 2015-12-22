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

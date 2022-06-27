# About
This is a simple application that's designed to pull a selection of cards from the Battle.net API, 
match it to the metadata it has, and displays the results. If REDIS_URL is defined, it will use that as a cache for
Battle.net API calls, however it is not required and will work without a cache.

# How To Use/Run

It is *highly suggested* that if running in a production environment with production api keys to maintain proper
security of your keys. This depends on how you run your app, but most hosted containerization platforms (such as AWS
ECS) provide secure means (Parameter Store/Secret Manager/Key Vault) of protecting your secrets.

### By Itself

Prerequisite: Ruby 3.0+

This is only suggested for development. Writing API keys to your terminal without precautions will save them in your
history.

Install dependencies

`bundle install`

Run application, filling in the appropriate environmental variables with your own. The REDIS_URL is an optional
parameter whose form is defined [here](https://www.iana.org/assignments/uri-schemes/prov/redis).

`BNET_ID=MYAPPID BNET_SECRET=MYAPPSECRET REDIS_URL=redis://redis/ rackup`

### In Docker

(Optional) build it yourself
`docker buildx build -o type=image,name=example-hearthstone .`

Run one-off using self-build
`docker run -e BNET_ID=MYAPPID -e BNET_SECRET=MYAPPSECRET -p 8000:8000 --name example-hearthstone example-hearthstone`

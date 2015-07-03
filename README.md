# hubot-redis-brain

A hubot script to return information about Katana URLs.

## Installation

In hubot project repo, run:

`npm install hubot-katana --save`

Then add **hubot-katana** to your `external-scripts.json`:

```json
[
  "hubot-katana"
]
```

## Configuration

hubot-katana doesn't require any configuration except the katana hostname which can be specified using the
`KATANA_HOSTNAME` environment.

For example, `export KATANA_HOSTNAME=katana` would look for URLs like http://katana/projects/Katana

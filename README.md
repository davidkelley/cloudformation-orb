`circleci config pack src/ > orb.yml`

`circleci orb publish orb.yml davidkelley/hello-user@dev:0.0.6`

`circleci orb validate orb.yml`
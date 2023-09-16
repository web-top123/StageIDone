# Manually migrating customers

There are three query parameters that you can use to control the
migration of a different account than your own.

The two key ones are `override` and `username`.

Going to `https://beta.idonethis.com/migrate/confirm?override=MIGRATION_OVERRIDE_KEY&username=USERNAME` will let you migrate the user with IDT1 username of `USERNAME`.
The `MIGRATION_OVERRIDE_KEY` you will find in the environment variables,
e.g. by running `heroku config`.

This will let you do the migration process as if you are that user.


## Migrating without forcing the redirect

There is a `migrated` boolean flag in the `accounts_user` table in the
IDT1 database that is flipped once a user is migrated. If that is true,
they will be redirected to IDT2.

If you for some reason wish to migrate someone without forcing that
redirect to IDT2, you can use the `validate` query parameter in the
migration URL.

Go to `https://beta.idonethis.com/migrate/confirm?override=MIGRATION_OVERRIDE_KEY&username=USERNAME&validate=0`.

This will also override any validation issues that might occurr
(although these are pretty rare as we don't have very strict validation
rules). Should you wish to not validate for some reason. If you migrate
without validation, you should log in as that user, make sure that
everything looks alright despite breaking validations and then flip the
flag in IDT1 if you want to force the redirect.

## Memory issues with migration

The migrator will read in all the source data from IDT1 before inserting
it into IDT2. Depending on the size of that blob of data, that can
consume _a lot_ of memory. For 95% of people, it will be very quick and
consume almost nothing, but once you start getting above 30,000 entries
it starts getting heavy.

Since Heroku has a 300 second timeout rule, for these really big
accounts you may have to migrate it on your own development machine or
on an EC2 instance with enough memory to run the migration.

Make sure to set `DATABASE_URL` to the IDT2 production database url,
`IDT1_DB_URL` to the IDT1 read-only database url and `IDT1_PROD_DB_URL`
to the IDT1 production database url. You can get all these URLs from the
configuration settings on Heroku.

I recommend starting up a basic EC2 instance and start up the app in
development mode there, just because you will be closer to the databases
as well as being able to create an instance with a lot of memory (like
32gb).

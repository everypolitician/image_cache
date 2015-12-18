# Image Cache

Cache images from EveryPolitician on GitHub pages' CDN.

## Deploying to Heroku

First click this button and following the setup instructions:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Then after the app has been created go to the Heroku Dashboard, select the newly created app and then provision the "Heroku Scheduler" add-on:

![screen shot 2015-12-18 at 17 27 21](https://cloud.githubusercontent.com/assets/22996/11902883/d946ce1e-a5ac-11e5-8798-15e5fa55ce77.png)

Once you've done that go to the [Scheduler Dashboard](https://scheduler.heroku.com/dashboard) and add a new job which runs `bin/image_cache` once an hour:

![screen shot 2015-12-18 at 17 26 56](https://cloud.githubusercontent.com/assets/22996/11902889/e574a080-a5ac-11e5-92b4-2f17fbb50c6c.png)

Your done! You can view the logs of the app using the following command, replacing `<app-name>` with the name of the app you created.

    heroku logs --tail --app <app-name>

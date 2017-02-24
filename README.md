# Image Cache

Build a Github Pages cache of Politician images for a country from EveryPolitician data.

## Disclaimer

Images referenced in EveryPolitician aren't necessarily free to use. You should check licensing etc before actively reusing them.

## Deploying to Heroku

First click this button and follow the setup instructions:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

You'll be able to choose a name for your new app. You'll also need to configure 4 settings:

- `IMAGE_SIZES` - This is a comma-separated list of the sizes of
  images you want to be generated. For example, if you want
  100x100 pixel thumbnails and the original versions, you should
  use: `IMAGE_SIZES=100x100,original`
- `GITHUB_REPO` - This should be the name of the repo you want to push the images to, in the form `user_or_org/repo_slug`.
- `GITHUB_ACCESS_TOKEN` - A [Personal Access Token](https://github.com/settings/tokens) with permission to push to the `GITHUB_REPO`.
- `EVERYPOLITICIAN_COUNTRY_SLUG` - The `slug` of the country you want to cache images for. Find slugs [in everypolitician-data's countries.json](https://github.com/everypolitician/everypolitician-data/blob/master/countries.json).

![screen shot 2015-12-18 at 18 03 03](https://cloud.githubusercontent.com/assets/22996/11903508/ac08685e-a5b1-11e5-891e-9522ab1400c7.png)

After the app has been created go to the Heroku Dashboard, select the newly created app and then click on the "Heroku Scheduler" add-on to get to the Scheduler Dashboard.

![screen shot 2015-12-18 at 18 07 06](https://cloud.githubusercontent.com/assets/22996/11903578/306afb20-a5b2-11e5-84f9-a0e9dfd3bff2.png)

On the Scheduler Dashboard add a new job which runs `bin/image_cache` once an hour:

![screen shot 2015-12-18 at 17 26 56](https://cloud.githubusercontent.com/assets/22996/11902889/e574a080-a5ac-11e5-92b4-2f17fbb50c6c.png)

You’re done! You can view the logs of the app using the following command, replacing `<app-name>` with the name of the app you created.

    heroku logs --tail --app <app-name>

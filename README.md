# AWS Lambdas

notion-movie-updater updates the movies on the Delian's and Lawrence's Notion Database
by either searching for the name of the movie (and taking the first result)
or by searching the IMDB ID.

Check out the API Docs at [https://delianpetrov.com/docs](https://documenter.getpostman.com/view/175422/2sB2ixiDHr#425ab2f0-7a40-432d-a5b4-1038bf7e58a8)

## Deploy

```sh
zip -r lambda_function.zip src Gemfile Gemfile.lock vendor && aws lambda update-function-code --function-name notion-movie-updater \
--zip-file fileb://lambda_function.zip
```

# Ruby Lambda Template

Oauth lambda function lives on [https://api.delianpetrov.com/oauth](https://api.delianpetrov.com/oauth)

If GET request to [https://api.delianpetrov.com/oauth/google](https://api.delianpetrov.com/oauth/google)
then it will try to authenticate and store client credentials for Google OAuth.

## Deploy

```sh
zip -r lambda_function.zip . && aws lambda update-function-code --function-name oauth \
--zip-file fileb://lambda_function.zip
```

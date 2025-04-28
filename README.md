# AWS Lambdas

Wrapper around Supabase to get/create user objects in the Supabase Users table.

API endpoint is at [https://api.delianpetrov.com/supabase/users](https://api.delianpetrov.com/supabase/users)

## Deploy

```sh
zip -r lambda_function.zip src Gemfile Gemfile.lock vendor && aws lambda update-function-code --function-name supabase \
--zip-file fileb://lambda_function.zip
```

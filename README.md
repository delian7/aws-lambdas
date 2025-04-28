# AWS Lambdas

notion_todos_fetcher is a lambda function with API at [https://api.delianpetrov.com/todos](https://api.delianpetrov.com/todos).
It fetches todos, creates and udpates todos (status as done or the date).

## Update the function

```sh
zip -r lambda_function.zip src Gemfile Gemfile.lock vendor && aws lambda update-function-code --function-name notion_todos_fetcher \
--zip-file fileb://lambda_function.zip
```

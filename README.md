# Notion Shortcuts

This repository contains useful shortcuts and tools for enhancing your Notion experience.

## AWS Lambda Deployment

To deploy the Notion Lambda application, use the following command:

```sh
zip -r lambda_function.zip src Gemfile Gemfile.lock vendor && aws lambda update-function-code --function-name create_notion_page \
--zip-file fileb://lambda_function.zip
```

This command will create a zip file of the current directory and update the AWS Lambda function `create_notion_page` with the new code.

## Getting Started

1. Clone the repository:

    ```sh
    git clone https://github.com/delian7/notion-shortcuts.git
    ```

2. Navigate to the project directory:

    ```sh
    cd notion-shortcuts
    ```

3. Follow the instructions in the to set up your environment and deploy the Lambda function.

    ```sh
    aws lambda update-function-configuration --function-name create_notion_page \
    --environment "Variables={NOTION_API_KEY=xxx,NOTION_RUBY_DATABASE_ID=xxx,NOTION_SYSTEM_DESIGN_DATABASE_ID=xxx,NOTION_JAVASCRIPT_DATABASE_ID=xxx}"
    ```

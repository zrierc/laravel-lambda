<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400" alt="Laravel Logo"></a></p>

<p align="center">
<a href="https://travis-ci.org/laravel/framework"><img src="https://travis-ci.org/laravel/framework.svg" alt="Build Status"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/dt/laravel/framework" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/v/laravel/framework" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/laravel/framework"><img src="https://img.shields.io/packagist/l/laravel/framework" alt="License"></a>
</p>

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

-   [Simple, fast routing engine](https://laravel.com/docs/routing).
-   [Powerful dependency injection container](https://laravel.com/docs/container).
-   Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
-   Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
-   Database agnostic [schema migrations](https://laravel.com/docs/migrations).
-   [Robust background job processing](https://laravel.com/docs/queues).
-   [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.

## Pre-requisite for deployment

Deployment model with [lambda-web-adapter](https://github.com/awslabs/aws-lambda-web-adapter) will deploy laravel app to AWS Lambda using a container base image. Different from using [bref](https://bref.sh/) that works out of the box, several steps and configurations need to be done to make all things work properly.

1. Tools

    - AWS Account.
    - [NodeJS](https://nodejs.org/en/) version >= `14.x`.
    - [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) version `1.5x.x`.
    - [Composer](https://getcomposer.org/) version >= `2.x.x`.

2. Configurations

    - Enable the `stderr` log driver in your Laravel app, to send logs to CloudWatch. This can be done by changing `LOG_CHANNEL` in `.env` file.

        ```bash
        # .env

        ...

        LOG_CHANNEL=stderr
        ...
        ```

        You also need to change log location to `stderr` in your nginx, php and php-fpm config file. Check out [references](#references) to visit each module configuration references or see simple example below:

        ```c
        # nginx.conf

        error_log /dev/stderr;
        ...
        ```

        ```c
        # php-custom.conf

        [www]
        ...

        php_admin_value[error_log] = /dev/stderr
        php_admin_flag[log_errors] = on
        ...
        ```

        ```c
        # php-fpm.conf

        [global]
        ...

        error_log = /dev/stderr
        ...
        ```

    - Since the default storage directory is read-only on Lambda. You need to move all cache directory to `/tmp` because that folder is only writeable directory on Lambda. For your laravel app, you can do this by adding `VIEW_COMPILED_PATH`. You also need to change `SESSION_DRIVER` to cookie because sessions cannot be stored to files.

        ```bash
        # .env
        ...
        VIEW_COMPILED_PATH='/tmp/storage/framework/views'

        SESSION_DRIVER=cookie
        ...
        ```

        The native Laravel storage directory is also read-only. You move the cache to `/tmp` to avoid errors. You can change cache location in `config/cache.php`. But, if you want to actively use the cache, it will be best to use the dynamodb driver instead.

        ```php
        # config/cache.php

        ...

        return [
          ...

          'stores' => [
            ...,

            'file' => [
              'driver' => 'file',
              'path' => storage_path('/tmp/storage/framework/cache'),
            ],

            ...,
          ],

          ...
        ];
        ```

        Make sure you also configure nginx, php, and php-fpm to change cache location to `/tmp`. This also applies to anything that can trigger writing files other than in `/tmp` folder including php extension that already installed. See the configuration examples for [nginx](https://github.com/awslabs/aws-lambda-web-adapter/tree/main/examples/php/app/conf.d) and [php-fpm](https://github.com/awslabs/aws-lambda-web-adapter/tree/main/examples/php/app/php-fpm.d) that lambda-web-adapter has provided.

    - Set a proper user(s) and group(s) premission to your nginx and php-fpm.

        > Check out [references](#references) to see each module configuration documentation or you can see [examples of each configuration](https://github.com/awslabs/aws-lambda-web-adapter/tree/main/examples/php/docker) given by lambda-web-adapter.

## Deployment

### Step 1: Configure [AWS Credentials](https://www.serverless.com/framework/docs/providers/aws/guide/credentials)

### Step 2: Create start-up script called `run.sh`

Since you need to start both nginx and php-fpm. You need to create a start-up script like the example below and call it inside Dockerfile as the default execution command.

```bash
#!/usr/bin/env sh
set -eu

php-fpm8

nginx -g 'daemon off;';
```

> The shebang or command at the first line may differ depending on the shell or base image that you use. The example above is using alpine linux as the base image.

### Step 3: Add one line to copy Lambda Web Adapter binary to /opt/extensions inside your `Dockefile`

```Dockerfile
...

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.4.0 /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT 8000

...

CMD ["run.sh"]
```

By default Lambda Web Adapter assumes the web app is listening on port 8080. You can specify the port if it is not running on the default port by adding environment variable called `PORT` inside Dockerfile as shown above.

> Lambda Web Adapter provides [custom configuration](https://github.com/awslabs/aws-lambda-web-adapter#configurations) that can be configured via environment variables like `PORT`.

### Step 3: Define AWS resources using `template.yaml`

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Transform: AWS::Serverless-2016-10-31
Description: >
    Deploying laravel app to lambda container using SAM

Globals:
    Function:
        Timeout: 180

Resources:
    LaravelFunc:
        Type: AWS::Serverless::Function
        Properties:
            CodeUri: ./
            MemorySize: 512
            PackageType: Image
            Architectures:
                - x86_64
            Events:
                Root:
                    Type: HttpApi
                    Properties:
                        Path: /
                        Method: ANY
                Proxy:
                    Type: HttpApi
                    Properties:
                        Path: /{proxy+}
                        Method: ANY
        Metadata:
            DockerTag: v1.0.0
            DockerContext: ./
            Dockerfile: Dockerfile

Outputs:
    NginxApi:
        Description: "API Gateway endpoint URL for Prod stage for Php application"
        Value: !Sub "https://${ServerlessHttpApi}.execute-api.${AWS::Region}.${AWS::URLSuffix}/"
```

See [AWS SAM template anatomy](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification-template-anatomy.html) to learn more about `template.yaml`.

### Step 4: Build your app

```bash
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

sam build
```

This command compiles the application, create image and prepares a deployment package in the `.aws-sam` sub-directory.

### Step 5: Deploy your app 🚀

To deploy your application for the first time, run the following in your shell:

```bash
sam deploy --guided
```

> With AWS Serverless Application Model (SAM), you can also invoke or test your lambda function locally. See [AWS SAM documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-test-and-debug.html) to learn more.

## References

If you get an error during the deployment proccess or want to learn more about lambda-web-adapter and AWS Serverless Application Model(SAM), take a look at the following resources:

-   [Laravel Documentation](https://laravel.com/docs/9.x/).
-   [AWS Lambda Official Docs](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html).
-   [Lambda Web Adapter Repository](https://github.com/awslabs/aws-lambda-web-adapter).
-   [AWS Serverless Application Model (SAM) Documentation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-getting-started.html).
-   [Nginx Documentation](https://nginx.org/en/docs/).
-   [Nginx Core Module References](https://nginx.org/en/docs/ngx_core_module.html).
-   [PHP Configuration Documentation](https://www.php.net/manual/en/configuration.file.php).
-   [PHP-FPM Documentation](https://www.php.net/manual/en/install.fpm.php).
-   [Simple PHP example provided by lambda-web-adapter](https://github.com/awslabs/aws-lambda-web-adapter/tree/main/examples/php)

If you have questions or found any problem let me know by opening issue - your feedback and contributions are welcome!

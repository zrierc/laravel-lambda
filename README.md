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

-   AWS Account.
-   NodeJS version >= `14.x`.
-   Serverless CLI version `2.72.2` or latest stable version (`v3.x.x`).
-   Composer version >= `2.x.x`.

## Deployment

### Step 1: Configure [AWS Credentials](https://www.serverless.com/framework/docs/providers/aws/guide/credentials).

### Step 2: Install [Bref](https://bref.sh/docs/installation.html)

```
composer require bref/bref bref/laravel-bridge --update-with-dependencies
```

### Step 3: Create Dockerfile

```Dockerfile:Dockerfile
FROM bref/php-80-fpm

COPY . /var/task

CMD ["public/index.php"]
```

If you need enable another PHP extensions, you can pulling them from [Bref Extensions](https://github.com/brefphp/extra-php-extensions), see [example](https://bref.sh/docs/web-apps/docker.html#docker-image).

### Step 4: setup serverless framework by creating serverless.yml file

```diff:serverless.yml
# Name of your services and aws resources
service: lara-app

# Enable serverless to read .env file (optional)
useDotenv: true

provider:
  name: aws
  # Default stage (default: dev)
  stage: prod
  # Default region (default: us-east-1)
  region: ap-southeast-1
  # # The AWS profile to use to deploy (default: "default" profile)
  profile: my-cool-profile
  # Set duration CloudWatch log retention
  logRetentionInDays: 3
  # Setup ECR Repository
  ecr:
    images:
      baseimage:
        path: ./

package:
  # Directories to exclude from deployment
  patterns:
    - "!node_modules/**"
    - "!public/storage"
    - "!resources/assets/**"
    - "!storage/**"
    - "!tests/**"

functions:
  # This function runs the Laravel website/API
  core-func:
    image:
      name: baseimage
    events:
      - httpApi: "*"

plugins:
  # Include the Bref plugin for PHP support
  - ./vendor/bref/bref
```

### Step 5: Deploy your app 🚀

```
sls deploy
```

## References

If you get an error during the deployment proccess or want to learn more about bref and serverless framework, take a look at the following resources:

-   [AWS Lambda Official Docs](https://docs.aws.amazon.com/lambda/latest/dg/welcome.html) [https://docs.aws.amazon.com/lambda/latest/dg/welcome.html]
-   [Bref Official Docs](https://bref.sh/) [https://bref.sh/]
-   [Serverless Framework](https://www.serverless.com/framework/docs/getting-started) [https://www.serverless.com/framework/docs/getting-started]
-   [`serverless.yml` References](https://www.serverless.com/framework/docs/providers/aws/guide/serverless.yml) [https://www.serverless.com/framework/docs/providers/aws/guide/serverless.yml]

If you have questions or found any problem let me know by opening issue - your feedback and contributions are welcome!

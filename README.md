# RUST AWS Lambda Example

## Pre-requisites

* [Docker](https://docs.docker.com/get-docker/)
* [Rust](https://www.rust-lang.org/tools/install)

Optional:
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

## Build

* **Building platform:** Intel x86-64 or Mac M1
* **Building OS:** Linux Mint 20.x or MacOS 12.5.1
* **Rust version**: 1.65.0

If you want musl build, set ENV var: `MUSL_LINKER=true`.

`./build.sh` autodetects if the host is an M1 mac and sets the target to the correct architecture.
It defaults to x86-64 gnu build.

**To build:**

```bash
./build.sh
# OR
MUSL_LINKER=true ./build.sh
```

## Deploy

Upload the zip file to AWS Lambda

##  Invoke AWS Lambda function from CLI:

```bash
aws lambda invoke \
    --function-name YOUR_AWS_FUNCTION_NAME \
    --payload '{ "name": "Testing007" }' \
    response.json \
&& echo "RESPONSE:" && cat response.json && echo
```

**Expected Response:**
```json
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```
```json
{"greeting":"Hello Rusty Lambda World! Received param name: Testing007! And param test was set!"}
```

### Troubleshooting

If getting the `Invalid base64:...` error, then try the following:

add `cli_binary_format=raw-in-base64-out` to the `~/.aws/config` file.

## Test locally

```bash
cargo run -- '{ "name": "Test123"}'
# or
cargo run -- '{ "name": "Test1234", "test": true }'
```

## aws-micro-cli

This tool is a minimalist replacement for `aws`, the [command line interface to Amazon Web Services](https://github.com/aws/aws-cli). It's implemented in Bash with only a few dependencies to other tools. The requests to the AWS API endpoints are done with [curl](https://curl.haxx.se/).

It can be used for example together with lightweight Linux distributions such as [Alpine Linux](https://alpinelinux.org/) to build very small docker images. It only supports a very limited number of commands and options but for these commands and options it aims to be as close as possible to the original. For example

```
    aws s3 cp foo.css s3://some-bucket/ --content-type text/css
```

can be replaced with the exact same commands/options

```
    aws-micro s3 cp foo.css s3://some-bucket/ --content-type text/css
```

This tool is not associated with Amazon in any way.

## Installation

Download the latest release, move it to some convenient location (e.g. `/usr/local/bin/`), set the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` and you're ready to go.

Make sure you have required unix tools installed. Assuming a fresh installation of macOS and minimal docker container images for the Linux distributions, you need to install:

| OS                                       | required packages   | optional packages |
| ---------------------------------------- | ------------------- | ----------------- |
| [macOS](https://www.apple.com/macos/)    | -                   | -                 |
| [Rocky Linux](https://rockylinux.org/)   | openssl             | file              |
| [Ubuntu](https://ubuntu.com/)            | openssl, curl       | file              |
| [Debian](https://www.debian.org/)        | openssl, curl       | file              |
| [Alpine Linux](https://alpinelinux.org/) | openssl, curl, bash | file              |

The package `file` is needed for content type detection.

If you clone the repo, be aware that `aws-micro` sources additional files and can only be run from the repo directory. The release version has everything merged into one single file.

## Compatibility

Supported services: `s3`, `s3api`, `sts`

Configuration settings and credentials set in `~/.aws` are ignored, with the exception of profiles (see below).
The path to the configuration file can be set with `AWS_CONFIG_FILE`. It defaults to `$HOME/.aws/config`.
Credentials must be configured via the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
The region can be set either via command line option or `AWS_DEFAULT_REGION`.
The output of `aws-micro` will in many cases differ from `aws`.

The s3 commands work also with S3-compatible services like [minio](https://github.com/minio/minio) and probably others.

## Supported commands and options

For a detailed description of the commands and option have a look at the aws-cli documentation.

Global options:

       --debug (boolean)

       --dryrun (boolean)
       (Contrary to `aws` this will work on all commands)

       --endpoint-url (string)

       --profile (string)
       (only `role_arn` in combination with `credential_source=Environment` is currently supported, no
       caching of temporary credentials)

       --region (string)

       --version (string)

       --no-sign-request (boolean)

### s3

`aws-micro` will only use virtual-hosted–style requests when used with AWS. This could break e.g. requests to buckets with `.` in the name. If a custom endpoint-url is set, a path-style request is used. See https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html and https://aws.amazon.com/blogs/aws/amazon-s3-path-deprecation-plan-the-rest-of-the-story/

S3Uri with S3 access points are not supported.

The content type detection will differ from `aws`. `aws-micro` should be able to detect more file types because it uses the `file` command which utilizes libmagic. See also https://github.com/aws/aws-cli/issues/2163. If `file` is not available no content type is set and a warning is print.

---

    cp <LocalPath> <S3Uri> or <S3Uri> <LocalPath>

Not supported:

    cp <S3Uri> <S3Uri>

Options:

    --acl (string)
    --no-guess-mime-type (boolean)
    --sse (string)
    --storage-class (string)
    --content-type (string)

---

    ls <S3Uri> or NONE

Output date/time will always be in UTC while `aws` would calculate the date/time for your timezone.
No additional option supported.

Known bugs:

- If the response is too big and split into multiple chunks (tag `<NextContinuationToken>` in the response), only the keys of the first response are shown and no further requests are done.

---

    mb <S3Uri>

### s3api

    create-bucket

Options:

    --bucket <value>

---

    head-object

Options:

    --bucket <value>
    --key <value>

### sts

    assume-role

Options:

    --role-arn <value>
    --role-session-name <value>

The output is in XML while `aws` will transform the output to JSON.

## Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog][kac] and this project adheres to [Semantic Versioning][semver].

[kac]: https://keepachangelog.com/
[semver]: https://semver.org/

### [v0.4.1](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.4.1) - 2024-11-05

#### Changed

- Improved `date` detection
- Improved argument handling
- Removed macos-12 from GitHub Actions as it will soon be deprecated

#### Fixed

- Use `~` instead of `$HOME`. The latter would result in an error in environments like AWS Lambda where `$HOME` is not set
- Return correct version

### [v0.4.0](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.4.0) - 2024-11-01

#### Added

- Command `s3api head-object` implemented.

#### Changed

- Updated GitHub Actions with current supported versions:
  - Added Ubuntu 24.04
  - Removed Debian 10
  - Removed macos-11, added macos-14 and macos-15
  - Removed Alpine 3.15 and 3.16, added 3.19 and 3.20

### [v0.3.0](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.3.0) - 2023-11-12

#### Added

- Command `s3 mb` implemented.
- Basic help for each command implemented.

#### Changed

- Various changes in GitHub Actions for testing different Linux distributions and versions:
  - Removed Ubuntu 18.04 as it's out of support and fails with actions/checkout v4.
  - Added Ubuntu "rolling" and Debian "unstable-slim".
  - Removed macos-10, added macos-13.
  - Removed Alpine 3.13 and 3.14, added 3.17 and 3.18

#### Fixed

- Set digest explicitly when calling `openssl sha256` to support Rocky Linux 9.

### [v0.2.1](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.2.1) - 2022-08-02

#### Fixed

- s3 ls lists keys inside folders correctly

### [v0.2.0](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.2.0) - 2020-06-28

#### Added

- Command `s3api create-bucket` implemented.
- Command `sts assume-role` implemented.
- Option `--acl` for `s3 cp` implemented.
- Option `--no-guess-mime-type` for `s3 cp` implemented.
- Option `--sse` for `s3 cp` implemented.
- Option `--storage-class` for `s3 cp` implemented.
- Option `--no-sign-request` implemented.
- Option `--profile` implemented.
- Environment variable `AWS_CONFIG_FILE` supported.

#### Changed

- If `file` is missing, no content type is set and a warning is print.
- When region us-east-1 is set, the local endpoint will be used (e.g. `bucket.s3.us-east-1.amazonaws.com`) instead of the global one.

#### Fixed

- Environment variable `AWS_DEFAULT_REGION` was ignored
- Handle different date format when listing buckets
- Output was missing when downloading files from S3
- s3 ls works now also without s3:// prefix
- Support of AWS S3 global endpoint if no region is specified

### [v0.1.0](https://github.com/sengaya/aws-micro-cli/releases/tag/v0.1.0) - 2020-05-23

- Initial public release.

## Contributing

Pull requests are welcome. The unit tests are written with https://github.com/bats-core/bats-core. Run with `bats tests/`. Make use of the excellent tool `shellcheck` (https://www.shellcheck.net/). Run with `shellcheck -x -a aws-micro`.

## License

Copyright 2020 Thilo Uttendorfer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

## aws-micro-cli

This tool aims to be a minimalist replacement for the `aws` command line utility. It's implemented in Bash with only a few dependencies to other tools. It can be used for example together with lightweight Linux distributions such as [Alpine Linux](https://alpinelinux.org/) to build very small docker images. It only supports a very limited number of commands and options but for these commands and options it aims to be as close as possible to the original. For example

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

Make sure you have required unix tools installed. Assuming fresh installation of macOS and minimal docker container images for the Linux distributions, you need to install:

| OS     | required packages   | optional packages |
---------|---------------------|-------------------|
| macos  | -                   | -                 |
| centos | openssl             | file              |
| ubuntu | openssl, curl       | file              |
| debian | openssl, curl       | file              |
| alpine | openssl, curl, bash | file              |

The package `file` is needed for content type detection.

If you clone the repo, be aware that `aws-micro` sources additional files and can only be run from the repo directory. The release version has everything merged into one single file.


## Compatibility

Supported services: `s3`

Configuration settings and credentials set in `~/.aws` are ignored.
Credentials must be configured via the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
The region can be set either via command line option or `AWS_DEFAULT_REGION`.
The output of `aws-micro` will in many cases differ from `aws`.

The s3 commands work also with S3-compatible services like [minio](https://github.com/minio/minio) and probably others.


## Supported commands and options

For a detailed description of the commands and option have a look at the aws-cli documentation.

Global options:

       --debug (boolean)

       --endpoint-url (string)

       --region (string)

       --dryrun (boolean)
       (Contrary to aws-cli this will work on all commands)

       --version (string)

### s3

`aws-micro` will only use virtual-hosted–style requests when used with AWS. This could break e.g. requests to buckets with `.` in the name. If a custom endpoint-url is set, a path-style request is used. See https://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html and https://aws.amazon.com/blogs/aws/amazon-s3-path-deprecation-plan-the-rest-of-the-story/

The content type detection will differ from `aws`. `aws-micro` should be able to detect more file types because it uses the `file` command which utilizes libmagic. See also https://github.com/aws/aws-cli/issues/2163.
If `file` is not available, `text/plain` will be used as a fallback.

---

    cp <LocalPath> <S3Uri> or <S3Uri> <LocalPath>

Not supported:

    cp <S3Uri> <S3Uri>

Options:

    --content-type (string)

---

    ls <S3Uri> or NONE

Output date/time will always be in UTC while `aws` would calculate the date/time for your timezone.
No additional option supported.

Known bug: Listing keys inside directories is not working correctly.


## Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog][kac] and this project adheres to [Semantic Versioning][semver].

[kac]: https://keepachangelog.com/
[semver]: https://semver.org/

### [Unreleased]

#### Changed
* If `file` is missing, use default content type `text/plain` and warn user.

### [0.1.0] - 2020-05-23

* Initial public release.


## Contributing

Pull requests are welcome. The unit tests are written with https://github.com/bats-core/bats-core. Make use of the excellent tool `shellcheck` (https://www.shellcheck.net/). Run with `shellcheck -x -a aws-micro`.


## License

Copyright 2020 Thilo Uttendorfer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

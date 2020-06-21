die() {
  local _ret="${2:-1}"
  test "${_PRINT_HELP:-}" = yes && print_help >&2
  echo "$1" >&2
  exit "${_ret}"
}

print_long_help() {
  echo "AWS-MICRO()                                                        AWS-MICRO()



NAME
       $0 -

DESCRIPTION
       The  AWS MICRO Command Line Interface is a replacement for aws-cli with
       minimal dependencies but also with a very limited support for services,
       (sub-)commands, parameters and options.

SYNOPSIS
          $0 [options] <command> <subcommand> [parameters]

       Use aws-micro command help for information on a  specific  command. The
       synopsis  for each  command  shows  its  parameters  and  their  usage.
       Optional parameters are shown in square brackets.

OPTIONS
       --debug (boolean)

       Turn on debug logging.

       --dryrun  (boolean)

       Displays  the  operations  that  would be performed using the specified
       command without actually running them.
       (Contrary to aws-cli this will work on all commands)

       --endpoint-url (string)

       Override command's default URL with the given URL.

       --profile (string)

       Use a specific profile from your credential file.

       --region (string)

       The region to use. Overrides config/env settings.

       --version (string)

       Display the version of this tool.

       --no-sign-request (boolean)

       Do  not  sign requests. Credentials will not be loaded if this argument
       is provided.

AVAILABLE SERVICES
       o s3

       o s3api

       o sts
"
}

print_help() {
  echo "usage: $0 [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  $0 help
  $0 <command> help
  $0 <command> <subcommand> help
"
}

_positionals=()
_arg_bucket=
_arg_content_type=
_arg_endpoint_url=
_arg_no_guess_mime_type="off"
_arg_no_sign_request="off"
_arg_profile=
_arg_role_arn=
_arg_role_session_name=
region=
DEBUG=0
curl_output="-s -S"
dryrun=

parse_commandline() {
  _positionals_count=0
  while test $# -gt 0
  do
    _key="$1"
    case "$_key" in
      --debug)
        DEBUG=1
        curl_output='-v'
        ;;
      --dryrun)
        dryrun="echo"
        ;;
      --no-guess-mime-type)
        _arg_no_guess_mime_type="on"
        ;;
      --no-sign-request)
        _arg_no_sign_request="on"
        ;;
      --content-type)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_content_type="$2"
        shift
        ;;
      --bucket)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_bucket="$2"
        shift
        ;;
      --endpoint-url)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_endpoint_url="$2"
        shift
        ;;
      --profile)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_profile="$2"
        shift
        ;;
      --region)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        region="$2"
        shift
        ;;
      --role-arn)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_role_arn="$2"
        shift
        ;;
      --role-session-name)
        test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
        _arg_role_session_name="$2"
        shift
        ;;
      --version)
        echo "$0 v0.1.0"
        exit 0
        ;;
      *)
        _last_positional="$1"
        _positionals+=("$_last_positional")
        _positionals_count=$((_positionals_count + 1))
        ;;
    esac
    shift
  done
}

handle_passed_args_count() {
  test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes die "$0: error: the following arguments are required: command" 1
}

assign_positional_args() {
  local _positional_name _shift_for=$1
  _positional_names="_arg_command _arg_subcommand"

  shift "$_shift_for"
  for _positional_name in ${_positional_names}; do
    test $# -gt 0 || break
    eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
    shift
  done
}

get_args() {
  parse_commandline "$@"
  handle_passed_args_count
  assign_positional_args 1 "${_positionals[@]}"
  service="${_arg_command:-}"
  if [[ -z "${region}" ]]; then
    region="${AWS_DEFAULT_REGION:-}"
  fi
  if [[ -z "${AWS_CONFIG_FILE:-}" ]]; then
    AWS_CONFIG_FILE="$HOME/.aws/config"
  fi
}

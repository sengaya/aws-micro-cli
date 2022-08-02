print_help_sts() {
  echo "Not yet implemented."
}

sts_assume-role() {
  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"
  http_method="POST"
  request_url="$(create_request_url "${service}" "" "${_arg_endpoint_url}" "${region}")"

  body="$(curl -Gso /dev/null -w '%{url_effective}' \
          --data 'Action=AssumeRole&Version=2011-06-15' \
          --data-urlencode "RoleArn=${_arg_role_arn}" \
          --data-urlencode "RoleSessionName=${_arg_role_session_name}" "" | cut -c 3- || true)"
  content_sha256="$(sha256 "${body}")"

  if [[ "${_arg_no_sign_request}" = "on" ]]; then
      ${dryrun} curl ${curl_output} --fail "${request_url}" --data "${body}"
  else
    headers=("host:$(get_host_from_request_url "$request_url")" "x-amz-date:${date}" "content-type:application/x-www-form-urlencoded;charset=utf-8" "${security_token_header:-}")
    set_headers

    # shellcheck disable=SC2086
    ${dryrun} curl ${curl_output} --fail \
      "${request_url}" \
      -H "Authorization:${authorization_header}" \
      ${curl_headers} \
      --data "${body}"
  fi
}

sts() {
  case "${_arg_subcommand:-}" in
    assume-role)
      sts_assume-role
      ;;
    help)
      print_help_sts
      exit 0
      ;;
    *)
      _PRINT_HELP=yes die "$0: error: argument subcommand: Invalid choice, valid choices are:

assume-role"
      ;;
  esac
}

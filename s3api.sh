print_help_s3api() {
  echo "Not yet implemented."
}

s3api_create-bucket() {
  [[ "${_positionals[2]:-}" = "help" ]] && print_help_s3api && exit 0

  if [[ "${_arg_bucket}" = "" ]]; then
    _PRINT_HELP=yes die "$0: error: the following arguments are required: --bucket"
  fi

  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"
  http_method="PUT"
  bucket="${_arg_bucket}"
  content_sha256="${empty_string_sha256}"
  request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "")"

  if [[ "${_arg_no_sign_request}" = "on" ]]; then
      ${dryrun} curl ${curl_output} --fail -X "${http_method}" "${request_url}" -H "Content-Length: 0" -o /dev/null
  else
    canonical_and_signed_headers="$(create_canonical_and_signed_headers "${http_method}" "${request_url}" "${content_sha256}" "${date}" "" "")"
    canonical_request="$(create_canonical_request "${http_method}" "${request_url}" "${canonical_and_signed_headers}" "${content_sha256}")"
    header_list="$(echo "${canonical_and_signed_headers}" | tail -1)"
    curl_headers="$(echo "${canonical_and_signed_headers}" | create_curl_headers)"
    string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${canonical_request}")"
    signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"
    authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "${header_list}")"
    # shellcheck disable=SC2086
    ${dryrun} curl ${curl_output} --fail -X "${http_method}" \
      "${request_url}" \
      -H "Authorization:${authorization_header}" \
      -H "Content-Length: 0" \
      ${curl_headers} -o /dev/null
  fi
}

s3api() {
  service='s3'
  case "${_arg_subcommand:-}" in
    create-bucket)
      s3api_create-bucket
      ;;
    help)
      print_help_s3api
      exit 0
      ;;
    *)
      _PRINT_HELP=yes die "$0: error: argument subcommand: Invalid choice, valid choices are:

create-bucket"
      ;;
  esac
}

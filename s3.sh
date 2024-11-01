print_help_s3() {
  print_command_help "s3" "cp ls mb"
}

s3_ls() {
  [[ "${_positionals[2]:-}" = "help" ]] && print_help_s3 && exit 0
  s3url="${_positionals[2]:-}" # s3url is optional

  if [[ "${s3url}" = "" ]]; then
    bucket=""
    key=""
    formatter="xml_to_text_for_buckets"
  else
    if is_s3url "${s3url}"; then
      bucket="$(get_bucket_from_s3url "${s3url}")"
      key="$(get_key_from_s3url "${s3url}")"
    else
      bucket="$(get_bucket_from_s3url "s3://${s3url}")"
      key="$(get_key_from_s3url "s3://${s3url}")"
    fi
    formatter="xml_to_text_for_keys"
  fi

  if [[ "${dryrun}" = "echo" ]]; then
    formatter="cat"
  fi

  http_method="GET"
  content_sha256="${empty_string_sha256}"
  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"

  request_url="$(create_request_url "${service}" ls "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"

  if [[ "${_arg_no_sign_request}" = "on" ]]; then
    # shellcheck disable=SC2086
    ${dryrun} curl ${curl_output} --fail "${request_url}" | "${formatter}"
  else
    headers=("host:$(get_host_from_request_url "$request_url")" "x-amz-content-sha256:${content_sha256}" "x-amz-date:${date}" "${security_token_header:-}")
    set_headers

    # shellcheck disable=SC2086
    ${dryrun} curl ${curl_output} --fail \
      "${request_url}" \
      -H "Authorization: ${authorization_header}" \
      ${curl_headers} | "${formatter}"
  fi
}

s3_mb() {
  [[ "${_positionals[2]:-}" = "help" ]] && print_help_s3 && exit 0

  if [[ "${#_positionals[@]}" -lt 3 ]]; then
    _PRINT_HELP=yes die "$0: error: the following arguments are required: paths"
  fi

  if ! is_s3url "${_positionals[2]}"; then
    _PRINT_HELP=no die "
<S3Uri>
Error: Invalid argument type"
  fi

  _arg_bucket="$(get_bucket_from_s3url "${_positionals[2]:-}")"
  s3api_create-bucket
  echo "make_bucket: ${_arg_bucket}"
}

s3_cp() {
  [[ "${_positionals[2]:-}" = "help" ]] && print_help_s3 && exit 0

  if [[ "${#_positionals[@]}" -lt 4 ]]; then
    _PRINT_HELP=yes die "$0: error: the following arguments are required: paths"
  else
    source="${_positionals[2]}"
    destination="${_positionals[3]}"
  fi

  if ! is_one_s3url_provided "$source" "$destination"; then
    die "usage: $0 s3 cp <LocalPath> <S3Uri> or <S3Uri> <LocalPath>
Error: Invalid argument type"  #  or <S3Uri> <S3Uri> (not yet implemented)
  fi

  if ! is_s3url "$source"; then
    if [[ ! -r "$source" ]]; then
      die "The user-provided path ${source} does not exist."
    fi
  fi

  if is_s3url "$source"; then
    http_method="GET"
    bucket="$(get_bucket_from_s3url "$source")"
    key="$(get_key_from_s3url "$source")"
    content_md5=""
    content_type=""
    content_sha256="${empty_string_sha256}"
    request_url="$(create_request_url "${service}" cp "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
  else
    http_method="PUT"
    bucket="$(get_bucket_from_s3url "${destination}")"
    key="$(get_key_from_s3url "${destination}")"
    content_md5="content-md5:$(md5_base64 "${source}")"
    content_type="$(get_mime "${source}" "${_arg_content_type}" "${_arg_no_guess_mime_type}")"
    if [[ -z "$key" ]]; then
      key="${source##*/}"
    fi
    request_url="$(create_request_url "${service}" cp "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
    protocol="$(get_protocol_from_request_url "${request_url}")"
    if [[ "${protocol}" = "https" ]];then
      content_sha256="UNSIGNED-PAYLOAD"
    else
      content_sha256="$(sha256 "${source}")"
    fi
  fi

  if [[ "${_arg_no_sign_request}" = "on" ]]; then
    if [[ "${http_method}" == "PUT" ]]; then
      # shellcheck disable=SC2086
      ${dryrun} curl ${curl_output} --fail -X "${http_method}" "${request_url}" --data-binary "@${source}" -o /dev/null
      echo "upload: ${source} to s3://${bucket}/${key}"
    else
      # shellcheck disable=SC2086
      ${dryrun} curl ${curl_output} --fail "${request_url}" -o "${destination}"
      echo "download: ${source} to ${destination}"
    fi
  else
    date="$(date -u +%Y%m%dT%H%M%SZ)"
    short_date="${date%%T*}"
    headers=("host:$(get_host_from_request_url "$request_url")" "x-amz-content-sha256:${content_sha256}" "x-amz-date:${date}" "${content_md5}" "${content_type}" "${security_token_header:-}" "${sse_header:-}" "${storage_class_header:-}" "${acl_header:-}")
    set_headers

    if [[ "${http_method}" == "PUT" ]]; then
      # shellcheck disable=SC2086
      ${dryrun} curl ${curl_output} --fail -X "${http_method}" \
        "${request_url}" \
        -H "Authorization:${authorization_header}" \
        ${curl_headers} \
        --data-binary "@${source}" -o /dev/null
      echo "upload: ${source} to s3://${bucket}/${key}"
    else
      # shellcheck disable=SC2086
      ${dryrun} curl ${curl_output} --fail \
        "${request_url}" \
        -H "Authorization: ${authorization_header}" \
        ${curl_headers} \
        -o "${destination}"
      echo "download: ${source} to ${destination}"
    fi
  fi
}

s3() {
  case "${_arg_subcommand:-}" in
    cp)
      s3_cp
      ;;
    ls)
      s3_ls
      ;;
    mb)
      s3_mb
      ;;
    help)
      print_help_s3
      exit 0
      ;;
    *)
      _PRINT_HELP=yes die "$0: error: argument subcommand: Invalid choice, valid choices are:

ls                                       | cp"
      ;;
  esac
}

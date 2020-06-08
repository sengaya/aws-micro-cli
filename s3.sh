print_help_s3() {
  echo "Not yet implemented."
}

s3_ls() {
  [[ "${_positionals[2]:-}" = "help" ]] && print_help_s3 && exit 0
  s3url="${_positionals[2]:-}" # s3url is optional

  if is_s3url "${s3url}"; then
    bucket="$(get_bucket_from_s3url "${s3url}")"
    key="$(get_key_from_s3url "${s3url}")"
    if [[ "${dryrun}" = "echo" ]]; then
        formatter="cat"
    else
        formatter="xml_to_text_for_keys"
    fi
  else
    bucket=""
    key=""
    if [[ "${dryrun}" = "echo" ]]; then
        formatter="cat"
    else
        formatter="xml_to_text_for_buckets"
    fi
  fi

  http_method="GET"
  content_sha256="${empty_string_sha256}"
  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"

  request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${http_method}" "${request_url}" "${content_sha256}" "${date}" "" "")"
  canonical_request="$(create_canonical_request "${http_method}" "${request_url}" "${canonical_and_signed_headers}" "${content_sha256}")"
  header_list="$(echo "${canonical_and_signed_headers}" | tail -1)"
  curl_headers="$(echo "${canonical_and_signed_headers}" | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | grep -v host | sed -e 's/.*/-H &/')"
  string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${canonical_request}")"
  signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"
  authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "${header_list}")"

  # shellcheck disable=SC2086
  ${dryrun} curl ${curl_output} --fail \
    "${request_url}" \
    -H "Authorization: ${authorization_header}" \
    ${curl_headers} | "${formatter}"
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
    request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
  else
    http_method="PUT"
    bucket="$(get_bucket_from_s3url "${destination}")"
    key="$(get_key_from_s3url "${destination}")"
    content_md5="$(md5_base64 "${source}")"
    content_type="$(get_mime "${source}" "${_arg_content_type}" "${_arg_no_guess_mime_type}")"
    if [[ -z "$key" ]]; then
      key="${source##*/}"
    fi
    request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
    protocol="$(get_protocol_from_request_url "${request_url}")"
    if [[ "${protocol}" = "https" ]];then
      content_sha256="UNSIGNED-PAYLOAD"
    else
      content_sha256="$(sha256 "${source}")"
    fi

  fi

  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"

  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${http_method}" "${request_url}" "${content_sha256}" "${date}" "${content_md5}" "${content_type}")"
  canonical_request="$(create_canonical_request "${http_method}" "${request_url}" "${canonical_and_signed_headers}" "${content_sha256}")"
  header_list="$(echo "${canonical_and_signed_headers}" | tail -1)"
  curl_headers="$(echo "${canonical_and_signed_headers}" | sed -e :a -e '$d;N;2,2ba' -e 'P;D' | grep -v host | sed -e 's/.*/-H &/')"
  string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${canonical_request}")"
  signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"
  authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "${header_list}")"

  if [[ "${http_method}" == "PUT" ]]; then
    # shellcheck disable=SC2086
    ${dryrun} curl ${curl_output} --fail -X "${http_method}" \
      "${request_url}" \
      -H "Authorization:${authorization_header}" \
      ${curl_headers} \
      --data-binary "@${source}"
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
}

s3() {
  case "${_arg_subcommand:-}" in
    cp)
      s3_cp
      ;;
    ls)
      s3_ls
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

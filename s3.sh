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
  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"

  request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
  req="$(create_canonical_request "${s3url}" "${request_url}" "" "${date}" "" "")"
  string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${req}")"
  signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"

  authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "host;x-amz-content-sha256;x-amz-date")"
  ${dryrun} curl ${curl_output} --fail \
    "${request_url}" \
    -H "Authorization: ${authorization_header}" \
    -H "X-Amz-Content-SHA256: ${empty_string_sha256}" \
    -H "X-Amz-Date: ${date}" | "${formatter}"
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
  else
    http_method="PUT"
    bucket="$(get_bucket_from_s3url "${destination}")"
    key="$(get_key_from_s3url "${destination}")"
    content_md5="$(md5_base64 "${source}")"
    content_type="${_arg_content_type:-$(guess_mime "${source}")}"
    if [[ -z "$key" ]]; then
      key="${source##*/}"
    fi
  fi

  date="$(date -u +%Y%m%dT%H%M%SZ)"
  short_date="${date%%T*}"

  request_url="$(create_request_url "${_arg_endpoint_url}" "${region}" "${bucket}" "${key}")"
  req="$(create_canonical_request "${source}" "${request_url}" "${bucket}" "${date}" "${content_md5}" "${content_type}")"
  content_sha256="$(echo "${req}" | tail -1)"
  string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${req}")"
  signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"

  if [[ "${http_method}" == "PUT" ]]; then
    authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "content-md5;content-type;host;x-amz-content-sha256;x-amz-date")"
    ${dryrun} curl ${curl_output} --fail -X "${http_method}" \
      "${request_url}" \
      -H "Authorization: ${authorization_header}" \
      -H "Content-Type: ${content_type}" \
      -H "X-Amz-Content-SHA256: ${content_sha256}" \
      -H "X-Amz-Date: ${date}" \
      -H "Content-MD5: ${content_md5}" \
      --data-binary "@${source}"
    echo "upload: ${source} to s3://${bucket}/${key}"
  else
    authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "host;x-amz-content-sha256;x-amz-date")"
    ${dryrun} curl ${curl_output} --fail \
      "${request_url}" \
      -H "Authorization: ${authorization_header}" \
      -H "X-Amz-Content-SHA256: ${empty_string_sha256}" \
      -H "X-Amz-Date: ${date}" \
      -o "${destination}"
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

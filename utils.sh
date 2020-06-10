empty_string_sha256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'


output_handler() {
  declare -r function_name="${1}"
  declare -r output="${2}"

  if [[ "${DEBUG}" == "1" ]]; then
    >&2 echo -n "DEBUG - ${function_name}: "
    echo "${output}" | tee /dev/stderr
  else
    echo "${output}"
  fi
}

get_mime() {
  declare -r file="${1}"
  declare -r custom_content_type="${2}"
  declare -r no_guess_mime_type_flag="${3}"

  if [[ "${no_guess_mime_type_flag}" = "on" ]]; then
    mime=""
  elif [[ -n "${custom_content_type}" ]]; then
    mime="${custom_content_type}"
  elif hash file 2>/dev/null; then
    mime="$(file -b --mime-type "${file}")"
  else
    >&2 echo "WARN - command 'file' not found, no content type set"
    mime=""
  fi

  output_handler "${FUNCNAME[0]}" "$mime"
}

is_s3url() {
  declare -r str="${1}"

  if [[ "${str}" =~ ^s3://[a-zA-Z0-9] ]]; then
    return 0
  else
    return 1
  fi
}

is_one_s3url_provided() {
  declare -r parameter1="${1}"
  declare -r parameter2="${2}"

  is_s3url "$parameter1"
  result1=$?
  is_s3url "$parameter2"
  result2=$?

  if [[ "$result1" == "0" && "$result2" == "0" ]]; then
    return 1
  elif [[ "$result1" == "1" && "$result2" == "1" ]]; then
    return 1
  elif [[ "$result1" == "0" && "$result2" == "1" ]]; then
    return 0
  elif [[ "$result1" == "1" && "$result2" == "0" ]]; then
    return 0
  else
    return 1
  fi
}

get_bucket_from_s3url() {
  declare -r s3url="${1}"
  [[ $s3url =~ ^s3://([^/]+)/?.* ]] && output_handler "${FUNCNAME[0]}" "${BASH_REMATCH[1]}"
}

get_key_from_s3url() {
  declare -r s3url="${1}"
  [[ $s3url =~ ^s3://[^/]+/?(.*) ]] && output_handler "${FUNCNAME[0]}" "${BASH_REMATCH[1]}"
}

md5_base64() {
  declare -r file="$1"
  openssl md5 -binary "$file" | openssl base64
}

sha256_hmac() {
  declare -r sig="$1"
  openssl sha256 -mac HMAC -macopt "$sig" -hex | sed 's/(stdin)= //'
}

sha256() {
  declare -r file_or_string="$1"

  if [[ -r "${file_or_string}" ]]; then
    hash="$(openssl dgst -sha256 <"${file_or_string}")"
  else
    hash="$(echo -n "${file_or_string}" | openssl dgst -sha256)"
  fi
  output_handler "${FUNCNAME[0]}" "${hash/* }"
}

get_host_from_request_url() {
  declare -r request_url="${1}"

  [[ $request_url =~ ^.*://([^/]+)/?.* ]] && output_handler "${FUNCNAME[0]}" "${BASH_REMATCH[1]}"
}

get_protocol_from_request_url() {
  declare -r request_url="${1}"

  [[ $request_url =~ ^(.*)://.* ]] && output_handler "${FUNCNAME[0]}" "${BASH_REMATCH[1]}"
}

get_canonical_uri() {
  declare -r request_url="${1}"

  remove_protocol="${request_url#*://}"
  output_handler "${FUNCNAME[0]}" "/${remove_protocol#*/}"
}

create_canonical_and_signed_headers() {
  declare -r http_method="${1}"
  declare -r request_url="${2}"
  declare -r content_sha256="${3}"
  declare -r date="${4}"
  declare -r content_md5="${5}"
  declare -r content_type="${6}"

  host="$(get_host_from_request_url "$request_url")"

  if [[ "${http_method}" == "GET" ]]; then
    canonical_headers="host:${host}
x-amz-content-sha256:${content_sha256}
x-amz-date:${date}

host;x-amz-content-sha256;x-amz-date"

  else
    if [[ "${content_md5}" = "" ]]; then
      content_md5_line=""
      content_md5_header=""
    else
      content_md5_line="content-md5:${content_md5}"$'\n'
      content_md5_header="content-md5;"
    fi
    if [[ "${content_type}" = "" ]]; then
      content_type_line=""
      content_type_header=""
    else
      content_type_line="content-type:${content_type}"$'\n'
      content_type_header="content-type;"
    fi
    canonical_headers="${content_md5_line}${content_type_line}host:${host}
x-amz-content-sha256:${content_sha256}
x-amz-date:${date}

${content_md5_header}${content_type_header}host;x-amz-content-sha256;x-amz-date"
  fi
  output_handler "${FUNCNAME[0]}" "${canonical_headers}"
}

create_canonical_request() {
  declare -r http_method="${1}"
  declare -r request_url="${2}"
  declare -r canonical_headers="${3}"
  declare -r content_sha256="${4}"

  canonical_uri="$(get_canonical_uri "${request_url}")"
  output_handler "${FUNCNAME[0]}" "${http_method}
${canonical_uri}

${canonical_headers}
${content_sha256}"
}

create_string_to_sign() {
  declare -r date="${1}"
  declare -r scope="${2}"
  declare -r req="${3}"

  hashed_req="$(sha256 "$req")"

  output_handler "${FUNCNAME[0]}" "AWS4-HMAC-SHA256
$date
$scope
$hashed_req"
}

create_signature() {
  declare -r string_to_sign="${1}"
  declare -r short_date="${2}"
  declare -r region="${3}"
  declare -r service="${4}"

  dateKey="$(echo -n "${short_date}" | sha256_hmac key:"AWS4${AWS_SECRET_ACCESS_KEY:-}")"
  regionKey="$(echo -n "${region}" | sha256_hmac hexkey:"${dateKey}")"
  serviceKey="$(echo -n "${service}" | sha256_hmac hexkey:"${regionKey}")"
  signingKey="$(echo -n "aws4_request" | sha256_hmac hexkey:"${serviceKey}")"

  echo -n "${string_to_sign}" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"${signingKey}" | sed 's/(stdin)= //'
}

create_authorization_header() {
  declare -r signature="${1}"
  declare -r short_date="${2}"
  declare -r region="${3}"
  declare -r service="${4}"
  declare -r signed_headers="${5}"

  output_handler "${FUNCNAME[0]}" "AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY_ID:-}/${short_date}/${region}/${service}/aws4_request, \
SignedHeaders=${signed_headers}, Signature=${signature}"
}

create_request_url() {
  declare -r custom_endpoint="${1}"
  declare -r region="${2}"
  declare -r bucket="${3}"
  declare -r key="${4}"

  if [[ -z "${custom_endpoint}" ]];then
    if [[ -z "${bucket}" && -z "${key}" ]]; then
      url="https://s3.${region}.amazonaws.com/"
    elif [[ -z "${key}" ]]; then
      url="https://${bucket}.s3.${region}.amazonaws.com/"
    else
      url="https://${bucket}.s3.${region}.amazonaws.com/${key}"
    fi
  else
    [[ "${custom_endpoint}" == */ ]] && endpoint="$custom_endpoint" || endpoint="$custom_endpoint/"
    if [[ -z "${bucket}" && -z "${key}" ]]; then
      url="${endpoint}"
    elif [[ -z "${key}" ]]; then
      url="${endpoint}${bucket}"
    else
      url="${endpoint}${bucket}/${key}"
    fi
  fi

  output_handler "${FUNCNAME[0]}" "${url//../.}" # replace .. with . in case no region given
}

xml_to_text_for_buckets() {
  # 1) add newlines to have each bucket in a seperate line
  # 2) grep for lines with buckets
  # 3) remove tags
  # 4) get bucket name and date and reformat

  # for macos/bsd compatility we use a quoted string in sed, see https://stackoverflow.com/a/18410122/1306877
  sed -E -e $'s:</?Buckets?>:&\\\n:g' \
  | grep '^<Name>' \
  | sed -e 's/<[^>]*>/ /g' \
  | while read -r bucket datetime_orig; do
      datetime="${datetime_orig/T/ }"
      echo "${datetime%.*} ${bucket}"
    done
}

xml_to_text_for_keys() {
  # 1) add newlines to have each key in a seperate line
  # 2) grep for lines with keys
  # 3) add spaces before tags
  # 4) add spaces after tags
  # 5) get key name, size and date and reformat

  # for macos/bsd compatility we use a quoted string in sed, see https://stackoverflow.com/a/18410122/1306877
  sed -E -e $'s:</?Contents?>:&\\\n:g' \
  | grep '^<Key>' \
  | sed -e 's:<: &:g' \
  | sed -e 's:>:& :g' \
  | while read -r _ key _ _ datetime_orig _ _ _ _ _ size _; do
      datetime="${datetime_orig/T/ }"
      if [[ "$key" =~ "/" ]]; then
        datetime="                   "
        size="PRE"
        key="${key%%/*}/"
        
      fi
      printf "${datetime%.*} %+10s %s${key}\n" "${size}"
    done | sed -n '
/ PRE /p
/ PRE /!H
${
  x
  s|\n||
  p
}' | uniq # Thanks to https://unix.stackexchange.com/a/587570/25979
}

AWS_MICRO_VERSION="v0.3.0"
empty_string_sha256='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'


print_command_help() {
  declare -r command="${1}"
  declare -r subcommands="${2}"
  echo "aws-micro ${AWS_MICRO_VERSION}

SYNOPSIS
          $0 [options] ${command} <subcommand> [parameters]

AVAILABLE SUBCOMMANDS"
for subcommand in ${subcommands}; do
  echo "       o ${subcommand}"
done
echo "
For details on the commands, subcommands and options use the official aws cli
command and the project page at https://github.com/sengaya/aws-micro"
}

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
    mime="content-type:${custom_content_type}"
  elif hash file 2>/dev/null; then
    mime="content-type:$(file -b --mime-type "${file}")"
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
  openssl sha256 -mac HMAC -sha256 -macopt "$sig" -hex | sed 's/.*(stdin)= //'
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

  _canonical_uri="${request_url#*://}"
  canonical_uri="/${_canonical_uri#*/}"
  output_handler "${FUNCNAME[0]}" "${canonical_uri%%\?*}"
}

get_canonical_query_string() {
  declare -r request_url="${1}"

  # "?" indicates a query string, extract, split, sort and join again
  if [[ ${request_url} == *"?"* ]]; then
    unsorted_canonical_query_string="${request_url#*\?}"
    IFS=$'&' read -r -a parameter_list <<< "$unsorted_canonical_query_string"
    while IFS=$'\n' read -r line; do sorted_parameters+=("$line"); done < <(array_sort "${parameter_list[@]}")
    canonical_query_string="$(join_by '&' "${sorted_parameters[@]}")"
  else
    canonical_query_string=""
  fi

  output_handler "${FUNCNAME[0]}" "${canonical_query_string}"
}

create_canonical_and_signed_headers() {
  declare -r headers=("$@")

  headers_list=()
  for header in "${headers[@]}"; do
    IFS=$':' read -r header_name _ <<< "$header"
    headers_list+=("${header_name}")
  done

  sorted_headers="$(array_sort "${headers[@]}")"
  sorted_headers_list=()
  while IFS='' read -r line; do sorted_headers_list+=("$line"); done < <(array_sort "${headers_list[@]}")
  sorted_delimited_headers_list="$(printf "%s;" "${sorted_headers_list[@]}")"

  canonical_headers="${sorted_headers}

${sorted_delimited_headers_list%;}"
  output_handler "${FUNCNAME[0]}" "${canonical_headers}"
}

create_canonical_request() {
  declare -r http_method="${1}"
  declare -r request_url="${2}"
  declare -r canonical_headers="${3}"
  declare -r content_sha256="${4}"

  canonical_uri="$(get_canonical_uri "${request_url}")"
  canonical_query_string="$(get_canonical_query_string "${request_url}")"
  output_handler "${FUNCNAME[0]}" "${http_method}
${canonical_uri}
${canonical_query_string}
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

  echo -n "${string_to_sign}" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"${signingKey}" | sed 's/.*(stdin)= //'
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

# from https://stackoverflow.com/a/10660730/1306877
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02X' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}

create_request_url() {
  declare -r service="${1}"
  declare -r command="${2}"
  declare -r custom_endpoint="${3}"
  declare -r region="${4}"
  declare -r bucket="${5:-}"
  declare -r key="${6:-}"

  # s3 ls
  if [[ "${service}" == "s3" ]] && [[ "${command}" == "ls" ]]; then
      if [[ -z "${custom_endpoint}" ]];then
        url="https://${bucket}.${service}.${region}.amazonaws.com/?list-type=2&prefix=$(rawurlencode "${key}")&delimiter=%2F&encoding-type=url"
      else
        if [[ -z "${bucket}" ]]; then
          url="${custom_endpoint}/"
        else
          url="${custom_endpoint}/${bucket}?list-type=2&prefix=$(rawurlencode "${key}")&delimiter=%2F&encoding-type=url"
        fi
      fi
  else
    # any other service / command
    if [[ -z "${custom_endpoint}" ]];then
      if [[ -z "${bucket}" && -z "${key}" ]]; then
        url="https://${service}.${region}.amazonaws.com/"
      elif [[ -z "${key}" ]]; then
        url="https://${bucket}.${service}.${region}.amazonaws.com/"
      else
        url="https://${bucket}.${service}.${region}.amazonaws.com/${key}"
      fi
    else
      # [[ "${custom_endpoint}" == */ ]] && endpoint="$custom_endpoint" || endpoint="$custom_endpoint/"
      if [[ -z "${bucket}" && -z "${key}" ]]; then
        url="${custom_endpoint}/"
      elif [[ -z "${key}" ]]; then
        url="${custom_endpoint}/${bucket}"
      else
        url="${custom_endpoint}/${bucket}/${key}"
      fi
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

# from https://stackoverflow.com/a/7052168/1306877
read_xml_dom() {
  local IFS=\>
  read -r -d \< entity content
}

xml_to_text_for_keys() {
  local content_flag=0
  local commonprefix_flag=0
  local key=""
  local lastmodified=""
  local size=""
  local prefix=""

  grep '<ListBucketResult' | while read_xml_dom; do
    if [[ "${commonprefix_flag}" == 0 && "${entity}" == "Prefix" ]]; then
      # only set folder if it does end with a slash
      if [[ "${content: -1}" == "/" ]]; then
        prefix="${content}"
      fi
    fi
    if [[ "${entity}" == "CommonPrefixes" ]]; then
      commonprefix_flag=1
    fi
    if [[ "${entity}" == "/CommonPrefixes" ]]; then
      commonprefix_flag=0
    fi
    if [[ "${entity}" == "Contents" ]]; then
      content_flag=1
    fi
    if [[ "${entity}" == "/Contents" ]]; then
      printf "${lastmodified%.*} %+10s %s${key##"${prefix}"}\n" "${size}"
      content_flag=0
    fi
    if [[ "${content_flag}" == 1 && "${entity}" == "LastModified" ]]; then
      lastmodified="${content/T/ }"
    fi
    if [[ "${content_flag}" == 1 && "${entity}" == "Size" ]]; then
      size="${content}"
    fi
    if [[ "${content_flag}" == 1 && "${entity}" == "Key" ]]; then
      key="${content}"
    fi
    if [[ "${commonprefix_flag}" == 1 && "${entity}" == "Prefix" ]]; then
      echo "                           PRE ${content##"${prefix}"}"
    fi
  done | sed -n '# Thanks to https://unix.stackexchange.com/a/587570/25979
/ PRE /p
/ PRE /!H
${
  x
  s|\n||
  p
}' | sed '/^$/d' # remove double newlines
}

create_curl_headers() {
  # 1) delete the last 2 lines
  # 2) remove host, not needed
  # 3) Add -H flag
  sed -e :a -e '$d;N;2,2ba' -e 'P;D' \
  | grep -v host \
  | sed -e 's/.*/-H &/'
}

# sets curl_headers and authorization_header, array "${headers[@]}" must be set before calling this function
set_headers() {
  declare headers_without_empty=()
  for header in "${headers[@]}"; do
    if [ -n "${header}" ]; then
      headers_without_empty+=("${header}")
    fi
  done

  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers_without_empty[@]}")"
  canonical_request="$(create_canonical_request "${http_method}" "${request_url}" "${canonical_and_signed_headers}" "${content_sha256}")"
  header_list="$(echo "${canonical_and_signed_headers}" | tail -1)"
  curl_headers="$(echo "${canonical_and_signed_headers}" | create_curl_headers)"
  string_to_sign="$(create_string_to_sign "${date}" "${short_date}/${region}/${service}/aws4_request" "${canonical_request}")"
  signature="$(create_signature "${string_to_sign}" "${short_date}" "${region}" "${service}")"
  authorization_header="$(create_authorization_header "${signature}" "${short_date}" "${region}" "${service}" "${header_list}")"
}

get_key_from_ini_file() {
  declare -r file="${1}"
  declare -r section="${2}"
  declare -r key="${3}"

  value="$(sed -n '/^[ \t]*\['"${section}"'\]/,/\[/s/^[ \t]*'"${key}"'[ \t]*=[ \t]*//p' "${file}")"
  output_handler "${FUNCNAME[0]}" "${value}"
}

get_access_key_id() {
  declare -r xml="${1}"

  tmp="${xml##*<AccessKeyId>}"
  output_handler "${FUNCNAME[0]}" "${tmp%%</AccessKeyId>*}"
}

get_secret_access_key() {
  declare -r xml="${1}"

  tmp="${xml##*<SecretAccessKey>}"
  output_handler "${FUNCNAME[0]}" "${tmp%%</SecretAccessKey>*}"
}

get_session_token() {
  declare -r xml="${1}"

  tmp="${xml##*<SessionToken>}"
  output_handler "${FUNCNAME[0]}" "${tmp%%</SessionToken>*}"
}

assume_role() {
  credential_source="$(get_key_from_ini_file "${AWS_CONFIG_FILE}" "profile ${_arg_profile}" credential_source)"
  if [[ "${credential_source}" = "Environment" ]]; then
    _arg_role_session_name="aws-micro-session-$RANDOM"
    _arg_role_arn="$(get_key_from_ini_file "${AWS_CONFIG_FILE}" "profile ${_arg_profile}" role_arn)"
    assume_role_response="$(service="sts" sts_assume-role)"

    AWS_ACCESS_KEY_ID="$(get_access_key_id "${assume_role_response}")"
    AWS_SECRET_ACCESS_KEY="$(get_secret_access_key "${assume_role_response}")"
    security_token="$(get_session_token "${assume_role_response}")"
    security_token_header="x-amz-security-token:${security_token}"
  else
    _PRINT_HELP=yes die "Only 'credential_source = Environment' supported."
  fi
}

# Inspired by array::sort() from https://github.com/labbots/bash-utility
array_sort() {
    declare -a array=("$@")
    declare -a sorted
    declare noglobtate
    noglobtate="$(shopt -po noglob)"
    set -o noglob
    declare IFS=$'\n'
    sorted=()
    while IFS=$'\n' read -r line; do sorted+=("$line"); done < <(sort <<< "${array[*]}")
    unset IFS
    eval "${noglobtate}"
    output_handler "${FUNCNAME[0]}" "$(printf "%s\n" "${sorted[@]}")"
}

# Inspired by array::contains() from https://github.com/labbots/bash-utility
array_contains() {
    declare query="${1:-}"
    shift
    for element in "${@}"; do
        [[ "${element}" == "${query}" ]] && return 0
    done
    return 1
}

# from https://stackoverflow.com/a/17841619/1306877
function join_by() {
   local IFS="$1"
   shift
   echo "$*"
}

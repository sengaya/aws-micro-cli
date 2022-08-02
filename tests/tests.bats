. utils.sh

@test "is_s3url should return 0 if s3 url" {
  run is_s3url "s3://foo/"
  [ "$status" -eq 0 ]
}

@test "is_s3url should return 1 if not s3 url" {
  run is_s3url "bar"
  [ "$status" -eq 1 ]
}

@test "is_s3url should fail if it does not contain bucket" {
  run is_s3url "s3://"
  [ "$status" -eq 1 ]
}

@test "is_one_s3url_provided should return 1 if zero s3 urls are provided" {
  run is_one_s3url_provided "foo" "bar"
  [ "$status" -eq 1 ]
}

@test "is_one_s3url_provided should return 1 if two s3 urls are provided" {
  run is_one_s3url_provided "s3://foo/" "s3://bar/"
  [ "$status" -eq 1 ]
}

@test "is_one_s3url_provided should return 0 if only first parameter is a s3 urls" {
  run is_one_s3url_provided "s3://foo/" "bar"
  [ "$status" -eq 0 ]
}

@test "is_one_s3url_provided should return 0 if only second parameter is a s3 urls" {
  run is_one_s3url_provided "foo" "s3://bar/"
  [ "$status" -eq 0 ]
}

@test "get_bucket_from_s3url should return bucket - s3url without trailing /" {
  run get_bucket_from_s3url "s3://foo"
  [ "$status" -eq 0 ]
  [ "$output" = "foo" ]
}

@test "get_bucket_from_s3url should return bucket - s3url with trailing /" {
  run get_bucket_from_s3url "s3://foo/"
  [ "$status" -eq 0 ]
  [ "$output" = "foo" ]
}

@test "get_bucket_from_s3url should return bucket - s3url with key" {
  run get_bucket_from_s3url "s3://foo/bar/object"
  [ "$status" -eq 0 ]
  [ "$output" = "foo" ]
}

@test "get_key_from_s3url should return nothing if no key provided" {
  run get_key_from_s3url "s3://bucket"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "get_key_from_s3url should return nothing if no key provided (with trailing slash)" {
  run get_key_from_s3url "s3://bucket/"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "get_key_from_s3url should return key" {
  run get_key_from_s3url "s3://bucket/key"
  [ "$status" -eq 0 ]
  [ "$output" = "key" ]
}

@test "get_key_from_s3url should return key including sub key" {
  run get_key_from_s3url "s3://bucket/foo/bar/key"
  [ "$status" -eq 0 ]
  [ "$output" = "foo/bar/key" ]
}

@test "md5_base64 should return bas64 encoded md5 hash" {
  run md5_base64 "/dev/null"
  [ "$status" -eq 0 ]
  [ "$output" = "1B2M2Y8AsgTpgAmY7PhCfg==" ]
}

@test "get_host_from_request_url should return host from request_url" {
  run get_host_from_request_url "http://127.0.0.1:9000"
  [ "$status" -eq 0 ]
  [ "$output" = "127.0.0.1:9000" ]
}

@test "get_host_from_request_url should return host from request_url with path" {
  run get_host_from_request_url "http://127.0.0.1:9000/bucket/key"
  [ "$status" -eq 0 ]
  [ "$output" = "127.0.0.1:9000" ]
}

@test "get_canonical_uri should return /key for request_url with bucket in host and key" {
  run get_canonical_uri "https://bucket.s3.eu-central-1.amazonaws.com/key"
  [ "$status" -eq 0 ]
  [ "$output" = "/key" ]
}

@test "get_canonical_uri should return / for request_url with bucket in host but no key" {
  run get_canonical_uri "https://bucket.s3.eu-central-1.amazonaws.com/"
  [ "$status" -eq 0 ]
  [ "$output" = "/" ]
}

@test "get_canonical_uri should return / for request_url with bucket in host but no key and s3url as source" {
  run get_canonical_uri "https://bucket.s3.eu-central-1.amazonaws.com/" "s3://bucket"
  [ "$status" -eq 0 ]
  [ "$output" = "/" ]
}

@test "get_canonical_uri should return /bucket/key for request_url with custom host and bucket+key" {
  run get_canonical_uri "http://127.0.0.1:9000/bucket/key"
  [ "$status" -eq 0 ]
  [ "$output" = "/bucket/key" ]
}

@test "get_canonical_uri should return / for request_url with custom host and no bucket+key" {
  run get_canonical_uri "http://127.0.0.1:9000/"
  [ "$status" -eq 0 ]
  [ "$output" = "/" ]
}

@test "get_canonical_uri should return /bucket for request_url with custom host and only bucket" {
  run get_canonical_uri "http://127.0.0.1:9000/bucket"
  [ "$status" -eq 0 ]
  [ "$output" = "/bucket" ]
}

@test "get_canonical_uri should return /bucket for request_url with parameters" {
  run get_canonical_uri "http://127.0.0.1:9000/bucket?list-type=2&prefix=&delimiter=%2F&encoding-type=url"
  [ "$status" -eq 0 ]
  [ "$output" = "/bucket" ]
}

@test "get_canonical_query_string should return sorted query string for request_url with parameters" {
  run get_canonical_query_string "http://127.0.0.1:9000/bucket?list-type=2&prefix=&delimiter=%2F&encoding-type=url"
  [ "$status" -eq 0 ]
  [ "$output" = "delimiter=%2F&encoding-type=url&list-type=2&prefix=" ]
}

@test "get_canonical_query_string should return empty string for request_url without parameters" {
  run get_canonical_query_string "http://127.0.0.1:9000/bucket"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "create_canonical_and_signed_headers should return a valid response" {
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f" "x-amz-date:20200525T185439Z" "content-md5:OnjOwdnDQYeocbNO+GjERg==" "content-type:text/plain")
  run create_canonical_and_signed_headers "${headers[@]}"
  [ "$status" -eq 0 ]
  [ "$output" = "content-md5:OnjOwdnDQYeocbNO+GjERg==
content-type:text/plain
host:127.0.0.1:9000
x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f
x-amz-date:20200525T185439Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date" ]
}

@test "set_headers should remove empty headers" {
  headers=("" "host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f" "" "x-amz-date:20200525T185439Z" "content-md5:OnjOwdnDQYeocbNO+GjERg==" "content-type:text/plain" "")
  set_headers
  [ "${canonical_and_signed_headers}" = "content-md5:OnjOwdnDQYeocbNO+GjERg==
content-type:text/plain
host:127.0.0.1:9000
x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f
x-amz-date:20200525T185439Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date" ]
}

@test "create_canonical_request with custom endpoint should return a valid request" {
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f" "x-amz-date:20200525T185439Z" "content-md5:OnjOwdnDQYeocbNO+GjERg==" "content-type:text/plain")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "PUT" "http://127.0.0.1:9000/bucket/key" "${canonical_and_signed_headers}" "1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f"
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/bucket/key

content-md5:OnjOwdnDQYeocbNO+GjERg==
content-type:text/plain
host:127.0.0.1:9000
x-amz-content-sha256:1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f
x-amz-date:20200525T185439Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
1337133a21760f3a65ba63dde142291b54c957f2d5ffa8741a769b06d779156f" ]
}

@test "create_canonical_request to AWS should return a valid request" {
  headers=("host:$(get_host_from_request_url "https://bucket.s3.amazonaws.com/key")" "x-amz-content-sha256:UNSIGNED-PAYLOAD" "x-amz-date:20200508T121510Z" "content-md5:07BzhNET7exJ6qYjitX/AA==" "content-type:text/plain")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "PUT" "https://bucket.s3.amazonaws.com/key" "${canonical_and_signed_headers}" "UNSIGNED-PAYLOAD"
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/key

content-md5:07BzhNET7exJ6qYjitX/AA==
content-type:text/plain
host:bucket.s3.amazonaws.com
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T121510Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_canonical_request to AWS for copy from s3 should return a valid request" {
  headers=("host:$(get_host_from_request_url "https://bucket.s3.amazonaws.com/key")" "x-amz-content-sha256:${empty_string_sha256}" "x-amz-date:20200508T121510Z")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "GET" "https://bucket.s3.amazonaws.com/key" "${canonical_and_signed_headers}" "${empty_string_sha256}"
  [ "$status" -eq 0 ]
  [ "$output" = "GET
/key

host:bucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20200508T121510Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]
}

@test "create_canonical_request to AWS with custom content type should return a valid request" {
  headers=("host:$(get_host_from_request_url "https://bucket.s3.amazonaws.com/key")" "x-amz-content-sha256:UNSIGNED-PAYLOAD" "x-amz-date:20200508T121510Z" "content-md5:07BzhNET7exJ6qYjitX/AA==" "content-type:foo/bar")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "PUT" "https://bucket.s3.amazonaws.com/key" "${canonical_and_signed_headers}" "UNSIGNED-PAYLOAD"
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/key

content-md5:07BzhNET7exJ6qYjitX/AA==
content-type:foo/bar
host:bucket.s3.amazonaws.com
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T121510Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_canonical_request to AWS for listing s3 content (no source) should return a valid request" {
  headers=("host:$(get_host_from_request_url "https://bucket.s3.amazonaws.com/")" "x-amz-content-sha256:${empty_string_sha256}" "x-amz-date:20200508T121510Z")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "GET" "https://bucket.s3.amazonaws.com/" "${canonical_and_signed_headers}" "${empty_string_sha256}"
  [ "$status" -eq 0 ]
  [ "$output" = "GET
/

host:bucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20200508T121510Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]
}

@test "create_canonical_request to AWS without content type should return a valid request" {
  headers=("host:$(get_host_from_request_url "https://bucket.s3.amazonaws.com/key")" "x-amz-content-sha256:UNSIGNED-PAYLOAD" "x-amz-date:20200508T121510Z" "content-md5:07BzhNET7exJ6qYjitX/AA==")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  run create_canonical_request "PUT" "https://bucket.s3.amazonaws.com/key" "${canonical_and_signed_headers}" "UNSIGNED-PAYLOAD"
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/key

content-md5:07BzhNET7exJ6qYjitX/AA==
host:bucket.s3.amazonaws.com
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T121510Z

content-md5;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_string_to_sign should return a valid string for signing" {
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" "x-amz-date:20200507T171310Z" "content-md5:1B2M2Y8AsgTpgAmY7PhCfg==" "content-type:inode/chardevice")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  req="$(create_canonical_request "PUT" "http://127.0.0.1:9000/bucket/key" "${canonical_and_signed_headers}" "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")"
  run create_string_to_sign "20200507T171310Z" "20200507/eu-west-3/s3/aws4_request" "$req"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256
20200507T171310Z
20200507/eu-west-3/s3/aws4_request
f309cf059b3420f219bb600099f1fef8ec9201847d4f0f590502814e52e12df1" ]
}

@test "create_signature should return a valid signature" {
  AWS_SECRET_ACCESS_KEY="key"
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c" "x-amz-date:20200507T231134Z" "content-md5:07BzhNET7exJ6qYjitX/AA==" "content-type:text/plain")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  req="$(create_canonical_request "PUT" "http://127.0.0.1:9000/bucket/key" "${canonical_and_signed_headers}" "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c")"
  string_to_sign="$(create_string_to_sign "20200507T231134Z" "20200507/eu-west-3/s3/aws4_request" "$req")"
  run create_signature "$string_to_sign" "20200507" "eu-west-3" "s3"
  [ "$status" -eq 0 ]
  [ "$output" = "c4d2791457e5adb7d84e392d8474aa0ad1fceeff8d0b6e404307a36c1203a5df" ]
}

@test "create_authorization_header should return a valid authorization header (PUT)" {
  AWS_ACCESS_KEY_ID="id"
  AWS_SECRET_ACCESS_KEY="key"
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c" "x-amz-date:20200507T231134Z" "content-md5:07BzhNET7exJ6qYjitX/AA==" "content-type:text/plain")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  req="$(create_canonical_request "PUT" "http://127.0.0.1:9000/bucket/key" "${canonical_and_signed_headers}" "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c")"
  string_to_sign="$(create_string_to_sign "20200507T231134Z" "20200507/eu-west-3/s3/aws4_request" "$req")"
  signature="$(create_signature "$string_to_sign" "20200507" "eu-west-3" "s3")"
  run create_authorization_header "$signature" "20200507" "eu-west-3" "s3" "content-md5;content-type;host;x-amz-content-sha256;x-amz-date"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256 Credential=id/20200507/eu-west-3/s3/aws4_request, SignedHeaders=content-md5;content-type;host;x-amz-content-sha256;x-amz-date, Signature=c4d2791457e5adb7d84e392d8474aa0ad1fceeff8d0b6e404307a36c1203a5df" ]
}

@test "create_authorization_header should return a valid authorization header (GET)" {
  AWS_ACCESS_KEY_ID="access-key-id"
  AWS_SECRET_ACCESS_KEY="secret-access-key"
  headers=("host:$(get_host_from_request_url "http://127.0.0.1:9000/bucket/key")" "x-amz-content-sha256:${empty_string_sha256}" "x-amz-date:20200527T134708Z")
  canonical_and_signed_headers="$(create_canonical_and_signed_headers "${headers[@]}")"
  req="$(create_canonical_request "GET" "http://127.0.0.1:9000/bucket/key" "${canonical_and_signed_headers}" "${empty_string_sha256}")"
  header_list="$(echo "${canonical_and_signed_headers}" | tail -1)"
  string_to_sign="$(create_string_to_sign "20200527T134708Z" "20200527/eu-west-3/s3/aws4_request" "$req")"
  signature="$(create_signature "$string_to_sign" "20200527" "eu-west-3" "s3")"
  run create_authorization_header "$signature" "20200527" "eu-west-3" "s3" "${header_list}"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256 Credential=access-key-id/20200527/eu-west-3/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=dcc54ccf39e5e32b8eea256eb5edde15b6afa8f90a2107b287dfb237fe025c00" ]
}

# test against data gathered from from aws cli
@test "create_request_url should return a valid request url (using create_request_url_test.data)" {
  grep -v "^#" tests/create_request_url_test.data | while IFS='|' read service command custom_endpoint region bucket key result_url ; do
    echo "Run create_request_url with ${service} ${command} ${custom_endpoint} ${region} ${bucket} ${key}"
    run create_request_url "${service}" "${command}" "${custom_endpoint}" "${region}" "${bucket}" "${key}"
    [ "$status" -eq 0 ]
    [ "$output" = "${result_url}" ]
  done
}

@test "xml_to_text_for_buckets should return list of buckets" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
#<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><Buckets><Bucket><Name>test-bucket</Name><CreationDate>2020-05-02T21:55:23.499Z</CreationDate></Bucket><Bucket><Name>test-bucket2</Name><CreationDate>2020-05-13T07:26:37.827Z</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>' | xml_to_text_for_buckets)"
  [ "$output" = "2020-05-02 21:55:23 test-bucket
2020-05-13 07:26:37 test-bucket2" ]
}

@test "xml_to_text_for_buckets should return list of buckets (time format from moto)" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
#<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><Buckets><Bucket><Name>test-bucket</Name><CreationDate>2020-05-02 21:55:23.123456</CreationDate></Bucket><Bucket><Name>test-bucket2</Name><CreationDate>2020-05-13 07:26:37.654321</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>' | xml_to_text_for_buckets)"
  [ "$output" = "2020-05-02 21:55:23 test-bucket
2020-05-13 07:26:37 test-bucket2" ]
}

@test "xml_to_text_for_keys should list keys" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-bucket</Name><Prefix></Prefix><Marker></Marker><MaxKeys>10000</MaxKeys><Delimiter></Delimiter><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2020-05-18T19:53:40.926Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "2020-05-18 19:53:40          4 test.txt" ]
}

@test "xml_to_text_for_keys should list keys and prefixes" {
  output="$(echo '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>landsat-pds</Name><Prefix></Prefix><KeyCount>12</KeyCount><MaxKeys>1000</MaxKeys><Delimiter>/</Delimiter><EncodingType>url</EncodingType><IsTruncated>false</IsTruncated><Contents><Key>index.html</Key><LastModified>2017-05-17T13:42:27.000Z</LastModified><ETag>&quot;ed18c8120c2e8303024d560d1a618158&quot;</ETag><Size>23767</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>robots.txt</Key><LastModified>2016-08-19T17:12:04.000Z</LastModified><ETag>&quot;b4714554348d9b6c1df58ddf5da4b14c&quot;</ETag><Size>105</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>run_info.json</Key><LastModified>2020-06-10T14:52:05.000Z</LastModified><ETag>&quot;20a76d643fddd15ad61cb29b423021c4&quot;</ETag><Size>73</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>run_list.txt</Key><LastModified>2020-06-10T14:52:05.000Z</LastModified><ETag>&quot;31febe6e72a2a2fdcc014f557f2b25c3&quot;</ETag><Size>3550</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>scene_list.gz</Key><LastModified>2018-08-29T00:45:15.000Z</LastModified><ETag>&quot;39c34d489777a595b36d0af5726007db&quot;</ETag><Size>45603307</Size><StorageClass>INTELLIGENT_TIERING</StorageClass></Contents><CommonPrefixes><Prefix>L8/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>c08f0e10-3a51-4a81-817f-76e5a3fcfff5/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>c1/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>runs/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>tarq/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>tarq_corrupt/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>test/</Prefix></CommonPrefixes></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "                           PRE L8/
                           PRE c08f0e10-3a51-4a81-817f-76e5a3fcfff5/
                           PRE c1/
                           PRE runs/
                           PRE tarq/
                           PRE tarq_corrupt/
                           PRE test/
2017-05-17 13:42:27      23767 index.html
2016-08-19 17:12:04        105 robots.txt
2020-06-10 14:52:05         73 run_info.json
2020-06-10 14:52:05       3550 run_list.txt
2018-08-29 00:45:15   45603307 scene_list.gz" ]
}

@test "xml_to_text_for_keys should list keys with 0-byte object" {
  output="$(echo '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>fah-public-data-covid19-cryptic-pockets</Name><Prefix>human/</Prefix><KeyCount>4</KeyCount><MaxKeys>1000</MaxKeys><Delimiter>/</Delimiter><EncodingType>url</EncodingType><IsTruncated>false</IsTruncated><Contents><Key>human/</Key><LastModified>2020-09-10T16:23:03.000Z</LastModified><ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag><Size>0</Size><StorageClass>STANDARD</StorageClass></Contents><CommonPrefixes><Prefix>human/ace2/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>human/il6/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>human/il6r/</Prefix></CommonPrefixes></ListBucketResult>' | xml_to_text_for_keys)"
  should="                           PRE ace2/
                           PRE il6/
                           PRE il6r/
2020-09-10 16:23:03          0 "
  [ "$output" = "$should" ]
}

@test "xml_to_text_for_keys should not return two newlines" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>fah-public-data-covid19-cryptic-pockets</Name><Prefix></Prefix><KeyCount>5</KeyCount><MaxKeys>1000</MaxKeys><Delimiter>/</Delimiter><EncodingType>url</EncodingType><IsTruncated>false</IsTruncated><CommonPrefixes><Prefix>HCoV-NL63/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>MERS-CoV/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>SARS-CoV-1/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>SARS-CoV-2/</Prefix></CommonPrefixes><CommonPrefixes><Prefix>human/</Prefix></CommonPrefixes></ListBucketResult>' | xml_to_text_for_keys | xxd)"
  should="$(echo '                           PRE HCoV-NL63/
                           PRE MERS-CoV/
                           PRE SARS-CoV-1/
                           PRE SARS-CoV-2/
                           PRE human/' | xxd )"
  [ "$output" = "$should" ]
}

@test "xml_to_text_for_keys should not remove folder if it does not end with a slash" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>fah-public-data-covid19-cryptic-pockets</Name><Prefix>human</Prefix><KeyCount>1</KeyCount><MaxKeys>1000</MaxKeys><Delimiter>/</Delimiter><EncodingType>url</EncodingType><IsTruncated>false</IsTruncated><CommonPrefixes><Prefix>human/</Prefix></CommonPrefixes></ListBucketResult>' | xml_to_text_for_keys)"
  should="                           PRE human/"
  echo "$output"
  [ "$output" = "$should" ]
}

@test "get_mime should return text/plain" {
  echo foo > .test.txt
  run get_mime ".test.txt" "" ""
  rm .test.txt
  [ "$status" -eq 0 ]
  [ "$output" = "content-type:text/plain" ]
}

@test "get_mime should return empty string when no_guess_mime_type_flag is set" {
  echo foo > .test.txt
  run get_mime ".test.txt" "" "on"
  rm .test.txt
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "get_mime should return custom mime type when set" {
  echo foo > .test.txt
  run get_mime ".test.txt" "text/css" "off"
  rm .test.txt
  [ "$status" -eq 0 ]
  [ "$output" = "content-type:text/css" ]
}

@test "s3api_create-bucket should fail if --bucket is not set" {
  run ./aws-micro s3api create-bucket
  [ "$status" -eq 1 ]
}

@test "create_curl_headers should return valid curl headers" {
  output="$(echo 'content-md5:EouJif1yvVNEpeJ2AvoIRA==
content-type:text/css
host:127.0.0.1:5000
x-amz-content-sha256:ac7d06088cf6d9d0a5f5ea8c126caadc786b49ea2f707bae3cb537724c1631c8
x-amz-date:20200617T212750Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date' | create_curl_headers)"
  [ "$output" = "-H content-md5:EouJif1yvVNEpeJ2AvoIRA==
-H content-type:text/css
-H x-amz-content-sha256:ac7d06088cf6d9d0a5f5ea8c126caadc786b49ea2f707bae3cb537724c1631c8
-H x-amz-date:20200617T212750Z" ]
}

@test "get_key_from_ini_file should return value of respective key" {
  echo -e "[foo]\nvar1=bar" > .test.ini
  run get_key_from_ini_file .test.ini foo var1
  rm .test.ini
  [ "$status" -eq 0 ]
  [ "$output" = "bar" ]
}

@test "get_key_from_ini_file should return value of respective key (lots of whitespaces)" {
  echo -e " [foo bar] \n var1 = foo\n   var2  =bar\n\n[foo bar2]\n" > .test.ini
  run get_key_from_ini_file .test.ini "foo bar" var2
  rm .test.ini
  [ "$status" -eq 0 ]
  [ "$output" = "bar" ]
}

@test "get_access_key_id should return AccessKeyId" {
  xml_response='<AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"> <AssumeRoleResult> <AssumedRoleUser> <AssumedRoleId>ASHGVDASJHGFDJADSHJAD:botocore-session-1234567890</AssumedRoleId> <Arn>arn:aws:sts::123456789012:assumed-role/foo-bar-role/botocore-session-1234567890</Arn> </AssumedRoleUser> <Credentials> <AccessKeyId>AIJHSBFDAJSHFBDAJSHF</AccessKeyId> <SecretAccessKey>fnksjdfnskjfn+dkfjnDkdjfnksdfsDKWdkbfdsk</SecretAccessKey> <SessionToken>Osdkfjsfksjnksjdfff//////////ksdjfndskjfnjnfskf7g4jnjksldnKJUfs823rhf8eufh8ufhufisdf+1234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567=</SessionToken> <Expiration>2019-01-10T20:14:07Z</Expiration> </Credentials> </AssumeRoleResult> <ResponseMetadata> <RequestId>a123456c-14tt-47g6-9f2f-123456789123</RequestId> </ResponseMetadata> </AssumeRoleResponse>'
  run get_access_key_id "${xml_response}"
  [ "$status" -eq 0 ]
  [ "$output" = "AIJHSBFDAJSHFBDAJSHF" ]
}

@test "get_secret_access_key should return SecretAccessKey" {
  xml_response='<AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"> <AssumeRoleResult> <AssumedRoleUser> <AssumedRoleId>ASHGVDASJHGFDJADSHJAD:botocore-session-1234567890</AssumedRoleId> <Arn>arn:aws:sts::123456789012:assumed-role/foo-bar-role/botocore-session-1234567890</Arn> </AssumedRoleUser> <Credentials> <AccessKeyId>AIJHSBFDAJSHFBDAJSHF</AccessKeyId> <SecretAccessKey>fnksjdfnskjfn+dkfjnDkdjfnksdfsDKWdkbfdsk</SecretAccessKey> <SessionToken>Osdkfjsfksjnksjdfff//////////ksdjfndskjfnjnfskf7g4jnjksldnKJUfs823rhf8eufh8ufhufisdf+1234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567=</SessionToken> <Expiration>2019-01-10T20:14:07Z</Expiration> </Credentials> </AssumeRoleResult> <ResponseMetadata> <RequestId>a123456c-14tt-47g6-9f2f-123456789123</RequestId> </ResponseMetadata> </AssumeRoleResponse>'
  run get_secret_access_key "${xml_response}"
  [ "$status" -eq 0 ]
  [ "$output" = "fnksjdfnskjfn+dkfjnDkdjfnksdfsDKWdkbfdsk" ]
}

@test "get_session_token should return SessionToken" {
  xml_response='<AssumeRoleResponse xmlns="https://sts.amazonaws.com/doc/2011-06-15/"> <AssumeRoleResult> <AssumedRoleUser> <AssumedRoleId>ASHGVDASJHGFDJADSHJAD:botocore-session-1234567890</AssumedRoleId> <Arn>arn:aws:sts::123456789012:assumed-role/foo-bar-role/botocore-session-1234567890</Arn> </AssumedRoleUser> <Credentials> <AccessKeyId>AIJHSBFDAJSHFBDAJSHF</AccessKeyId> <SecretAccessKey>fnksjdfnskjfn+dkfjnDkdjfnksdfsDKWdkbfdsk</SecretAccessKey> <SessionToken>Osdkfjsfksjnksjdfff//////////ksdjfndskjfnjnfskf7g4jnjksldnKJUfs823rhf8eufh8ufhufisdf+1234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567=</SessionToken> <Expiration>2019-01-10T20:14:07Z</Expiration> </Credentials> </AssumeRoleResult> <ResponseMetadata> <RequestId>a123456c-14tt-47g6-9f2f-123456789123</RequestId> </ResponseMetadata> </AssumeRoleResponse>'
  run get_session_token "${xml_response}"
  [ "$status" -eq 0 ]
  [ "$output" = "Osdkfjsfksjnksjdfff//////////ksdjfndskjfnjnfskf7g4jnjksldnKJUfs823rhf8eufh8ufhufisdf+1234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567891234567=" ]
}

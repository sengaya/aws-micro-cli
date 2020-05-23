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

@test "create_canonical_request with custom endpoint should return a valid request (http)" {
  run create_canonical_request "/dev/null" "http://127.0.0.1:9000/bucket/key" "bucket" "20200507T171310Z" "1B2M2Y8AsgTpgAmY7PhCfg==" "inode/chardevice"
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/bucket/key

content-md5:1B2M2Y8AsgTpgAmY7PhCfg==
content-type:inode/chardevice
host:127.0.0.1:9000
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20200507T171310Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]
}

@test "create_canonical_request with custom endpoint should return a valid request (https)" {
  echo foo > .test.txt
  run create_canonical_request ".test.txt" "https://127.0.0.1:9000/bucket/key" "bucket" "20200508T083044Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain"
  rm .test.txt
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/bucket/key

content-md5:07BzhNET7exJ6qYjitX/AA==
content-type:text/plain
host:127.0.0.1:9000
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T083044Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_canonical_request to AWS should return a valid request" {
  echo foo > .test.txt
  run create_canonical_request ".test.txt" "https://bucket.s3.amazonaws.com/key" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain"
  rm .test.txt
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

@test "create_canonical_request to AWS without key should return a valid request with source filename as key" {
  echo foo > .test.txt
  run create_canonical_request ".test.txt" "https://bucket.s3.amazonaws.com/.test.txt" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain"
  rm .test.txt
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/.test.txt

content-md5:07BzhNET7exJ6qYjitX/AA==
content-type:text/plain
host:bucket.s3.amazonaws.com
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T121510Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_canonical_request to AWS without key should return a valid request with source filename as key (filename with path)" {
  mkdir -p .test-dir
  echo foo > .test-dir/.test.txt
  run create_canonical_request ".test-dir/.test.txt" "https://bucket.s3.amazonaws.com/.test.txt" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain"
  rm .test-dir/.test.txt
  rmdir .test-dir
  [ "$status" -eq 0 ]
  [ "$output" = "PUT
/.test.txt

content-md5:07BzhNET7exJ6qYjitX/AA==
content-type:text/plain
host:bucket.s3.amazonaws.com
x-amz-content-sha256:UNSIGNED-PAYLOAD
x-amz-date:20200508T121510Z

content-md5;content-type;host;x-amz-content-sha256;x-amz-date
UNSIGNED-PAYLOAD" ]
}

@test "create_canonical_request to AWS for copy from s3 should return a valid request" {
  run create_canonical_request "s3://bucket/key" "https://bucket.s3.amazonaws.com/key" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA=="
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
  echo foo > .test.txt
  run create_canonical_request ".test.txt" "https://bucket.s3.amazonaws.com/key" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA==" "foo/bar"
  rm .test.txt
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
  run create_canonical_request "" "https://bucket.s3.amazonaws.com/" "bucket" "20200508T121510Z" "07BzhNET7exJ6qYjitX/AA=="
  [ "$status" -eq 0 ]
  [ "$output" = "GET
/

host:bucket.s3.amazonaws.com
x-amz-content-sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
x-amz-date:20200508T121510Z

host;x-amz-content-sha256;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]
}

@test "create_string_to_sign should return a valid string for signing" {
  req="$(create_canonical_request "/dev/null" "http://127.0.0.1:9000/bucket/key" "bucket" "20200507T171310Z" "1B2M2Y8AsgTpgAmY7PhCfg==" "inode/chardevice")"
  run create_string_to_sign "20200507T171310Z" "20200507/eu-west-3/s3/aws4_request" "$req"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256
20200507T171310Z
20200507/eu-west-3/s3/aws4_request
f309cf059b3420f219bb600099f1fef8ec9201847d4f0f590502814e52e12df1" ]
}

@test "create_signature should return a valid signature" {
  AWS_SECRET_ACCESS_KEY="key"
  echo foo > .test.txt
  req="$(create_canonical_request ".test.txt" "http://127.0.0.1:9000/bucket/key" "bucket" "20200507T231134Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain")"
  rm .test.txt
  string_to_sign="$(create_string_to_sign "20200507T231134Z" "20200507/eu-west-3/s3/aws4_request" "$req")"
  run create_signature "$string_to_sign" "20200507" "eu-west-3" "s3"
  [ "$status" -eq 0 ]
  [ "$output" = "c4d2791457e5adb7d84e392d8474aa0ad1fceeff8d0b6e404307a36c1203a5df" ]
}

@test "create_authorization_header should return a valid authorization header (PUT)" {
  AWS_ACCESS_KEY_ID="id"
  AWS_SECRET_ACCESS_KEY="key"
  echo foo > .test.txt
  req="$(create_canonical_request ".test.txt" "http://127.0.0.1:9000/bucket/key" "bucket" "20200507T231134Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain")"
  rm .test.txt
  string_to_sign="$(create_string_to_sign "20200507T231134Z" "20200507/eu-west-3/s3/aws4_request" "$req")"
  signature="$(create_signature "$string_to_sign" "20200507" "eu-west-3" "s3")"
  run create_authorization_header "$signature" "20200507" "eu-west-3" "s3" "content-md5;content-type;host;x-amz-content-sha256;x-amz-date"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256 Credential=id/20200507/eu-west-3/s3/aws4_request, SignedHeaders=content-md5;content-type;host;x-amz-content-sha256;x-amz-date, Signature=c4d2791457e5adb7d84e392d8474aa0ad1fceeff8d0b6e404307a36c1203a5df" ]
}

@test "create_authorization_header should return a valid authorization header (GET)" {
  AWS_ACCESS_KEY_ID="id"
  AWS_SECRET_ACCESS_KEY="key"
  echo foo > .test.txt
  req="$(create_canonical_request ".test.txt" "http://127.0.0.1:9000/bucket/key" "bucket" "20200507T231134Z" "07BzhNET7exJ6qYjitX/AA==" "text/plain")"
  rm .test.txt
  string_to_sign="$(create_string_to_sign "20200507T231134Z" "20200507/eu-west-3/s3/aws4_request" "$req")"
  signature="$(create_signature "$string_to_sign" "20200507" "eu-west-3" "s3")"
  run create_authorization_header "$signature" "20200507" "eu-west-3" "s3" "host;x-amz-content-sha256;x-amz-date"
  [ "$status" -eq 0 ]
  [ "$output" = "AWS4-HMAC-SHA256 Credential=id/20200507/eu-west-3/s3/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=c4d2791457e5adb7d84e392d8474aa0ad1fceeff8d0b6e404307a36c1203a5df" ]
}

@test "create_request_url should return a valid endpoint (us-east-1)" {
  run create_request_url "" "us-east-1" "bucket" "key"
  [ "$status" -eq 0 ]
  [ "$output" = "https://bucket.s3.amazonaws.com/key" ]
}

@test "create_request_url should return a valid endpoint (other region)" {
  run create_request_url "" "eu-central-1" "bucket" "key"
  [ "$status" -eq 0 ]
  [ "$output" = "https://bucket.s3.eu-central-1.amazonaws.com/key" ]
}

@test "create_request_url should return a valid endpoint (custom endpoint)" {
  run create_request_url "https://custom.endpoint" "eu-central-1" "bucket" "key"
  [ "$status" -eq 0 ]
  [ "$output" = "https://custom.endpoint/bucket/key" ]
}

@test "create_request_url should return a valid endpoint (custom endpoint, no bucket/key)" {
  run create_request_url "https://custom.endpoint/" "foo" "" ""
  [ "$status" -eq 0 ]
  [ "$output" = "https://custom.endpoint/" ]
}

@test "create_request_url should return a valid endpoint (custom endpoint, no bucket/key, slash added)" {
  run create_request_url "https://custom.endpoint" "foo" "" ""
  [ "$status" -eq 0 ]
  [ "$output" = "https://custom.endpoint/" ]
}

@test "create_request_url should return a valid endpoint if no bucket is supplied (other region)" {
  run create_request_url "" "eu-central-1" "" ""
  [ "$status" -eq 0 ]
  [ "$output" = "https://s3.eu-central-1.amazonaws.com/" ]
}

@test "xml_to_text_for_buckets should return list of buckets" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
#<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><Buckets><Bucket><Name>test-bucket</Name><CreationDate>2020-05-02T21:55:23.499Z</CreationDate></Bucket><Bucket><Name>test-bucket2</Name><CreationDate>2020-05-13T07:26:37.827Z</CreationDate></Bucket></Buckets></ListAllMyBucketsResult>' | xml_to_text_for_buckets)"
  [ "$output" = "2020-05-02 21:55:23 test-bucket
2020-05-13 07:26:37 test-bucket2" ]
}

@test "xml_to_text_for_keys should return list of keys" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-bucket</Name><Prefix></Prefix><Marker></Marker><MaxKeys>10000</MaxKeys><Delimiter></Delimiter><IsTruncated>false</IsTruncated><Contents><Key>test.txt</Key><LastModified>2020-05-18T19:53:40.926Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "2020-05-18 19:53:40          4 test.txt" ]
}

@test "xml_to_text_for_keys should return list of keys and directories" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-bucket</Name><Prefix></Prefix><Marker></Marker><MaxKeys>10000</MaxKeys><Delimiter></Delimiter><IsTruncated>false</IsTruncated><Contents><Key>dir/test2.txt</Key><LastModified>2020-05-18T22:14:30.382Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test.txt</Key><LastModified>2020-05-18T19:53:40.926Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "                           PRE dir/
2020-05-18 19:53:40          4 test.txt" ]
}

@test "xml_to_text_for_keys should return list of keys and directories in correct order" {
  output="$(echo '<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-bucket</Name><Prefix></Prefix><Marker></Marker><MaxKeys>10000</MaxKeys><Delimiter></Delimiter><IsTruncated>false</IsTruncated><Contents><Key>random-file</Key><LastModified>2020-05-18T21:44:53.978Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>54</Size><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>sub1/sub2/test2.txt</Key><LastModified>2020-05-18T21:52:23.410Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test.txt</Key><LastModified>2020-05-18T19:53:40.934Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test2.txt</Key><LastModified>2020-05-18T21:17:13.617Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>foobar.txt</Key><LastModified>2020-05-18T19:53:40.938Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>upload.txt</Key><LastModified>2020-05-18T19:53:40.942Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "                           PRE sub1/
2020-05-18 21:44:53         54 random-file
2020-05-18 19:53:40          4 test.txt
2020-05-18 21:17:13          4 test2.txt
2020-05-18 19:53:40          4 foobar.txt
2020-05-18 19:53:40          4 upload.txt" ]
}

@test "xml_to_text_for_keys should return directories only once" {
  output="$(echo '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>test-bucket</Name><Prefix></Prefix><Marker></Marker><MaxKeys>10000</MaxKeys><Delimiter></Delimiter><IsTruncated>false</IsTruncated><Contents><Key>random-file</Key><LastModified>2020-05-18T21:44:53.978Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>54</Size><Owner><ID>17be0943d07d67113ab42f028a8bd346a913fc98d79da0dfb84754dee3a89aca</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>sub1/sub2/test2.txt</Key><LastModified>2020-05-18T21:52:23.410Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>sub1/test.txt</Key><LastModified>2020-05-20T21:32:57.045Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test.txt</Key><LastModified>2020-05-18T19:53:40.934Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test2.txt</Key><LastModified>2020-05-18T21:17:13.617Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>foobar.txt</Key><LastModified>2020-05-18T19:53:40.938Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>upload.txt</Key><LastModified>2020-05-18T19:53:40.942Z</LastModified><ETag>&#34;1cae7d2f9dfb30f1bbf5e3e8a698a45d&#34;</ETag><Size>4</Size><Owner><ID>02d6176db174dc93cb1b899f7c6078f08654445fe8cf1b6ce98d8855f66bdbf4</ID><DisplayName></DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>' | xml_to_text_for_keys)"
  [ "$output" = "                           PRE sub1/
2020-05-18 21:44:53         54 random-file
2020-05-18 19:53:40          4 test.txt
2020-05-18 21:17:13          4 test2.txt
2020-05-18 19:53:40          4 foobar.txt
2020-05-18 19:53:40          4 upload.txt" ]
}

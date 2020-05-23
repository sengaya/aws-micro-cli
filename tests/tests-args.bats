. args.sh

@test "aws-micro should return error if command not supported" {
  run ./aws-micro foo
  [ "$status" -eq 1 ]
}

@test "aws-micro with s3 and no subcommand should fail" {
  run ./aws-micro s3
  [ "$status" -eq 1 ]
}

@test "get_args s3 ls should return command and subcommand" {
  get_args s3 ls
  [ "$?" -eq 0 ]
  [ "${_arg_command}" = "s3" ]
  [ "${_arg_subcommand}" = "ls" ]
}

@test "get_args should set --debug args" {
  get_args s3 ls --debug
  [ "$?" -eq 0 ]
  [ "${_arg_command}" = "s3" ]
  [ "${_arg_subcommand}" = "ls" ]
  [ "$DEBUG" = "1" ]
}

@test "get_args should set --dryrun args" {
  get_args s3 ls --dryrun
  [ "$?" -eq 0 ]
  [ "${_arg_command}" = "s3" ]
  [ "${_arg_subcommand}" = "ls" ]
  [ "$dryrun" = "echo" ]
}

@test "get_args should return command with other args" {
  get_args --debug s3 --dryrun ls
  [ "$?" -eq 0 ]
  [ "${_arg_command}" = "s3" ]
  [ "${_arg_subcommand}" = "ls" ]
}

@test "aws-micro s3 cp should fail if not at least 2 more subcommands" {
  run ./aws-micro s3 cp
  [ "$status" -eq 1 ]
}

@test "aws-micro s3 cp should fail if not at least 2 more subcommands" {
  run ./aws-micro s3 cp foo
  [ "$status" -eq 1 ]
}

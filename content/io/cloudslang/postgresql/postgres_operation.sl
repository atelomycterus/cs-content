########################################################################################################################
#!!
#! @description: This flow allows operating (start/stop/restart/reload) on existing postgres database.
#!
#! @input hostname: Hostname or IP address of the target machine
#! @input username: Username used to connect to the target machine
#! @input password: The root or priviledged account password
#! @input proxy_host: The proxy server used to access the remote machine
#!                    Optional
#! @input proxy_port: The proxy server port
#!                    Valid values: -1 and numbers greater than 0
#!                    Default: '8080'
#!                    Optional
#! @input proxy_username: The user name used when connecting to the proxy
#!                        Optional
#! @input proxy_password: The proxy server password associated with the proxy_username input value
#!                        Optional
#! @input connection_timeout: Time in milliseconds to wait for the connection to be made
#!                            Default value: '10000'
#!                            Optional
#! @input execution_timeout: Time in milliseconds to wait for the command to complete
#!                           Default: '90000'
#!                           Optional
#! @input	installation_location: The full path to the location where PostgreSQL was installed
#!                               Default: '90000'
#! @input	start_on_boot: A flag to indicate if server should be restart after configuration
#!                       Valid values: 'yes' or 'no'
#!                       Optional
#! @input operation: The operation to be performed
#!                   Valid values: stop, start, restart, reload
#!                   Optional
#! @input private_key_file: Absolute path to private key file
#!                          Optional
#! @input pg_ctl_location: Path of the pg_ctl binary
#!                         Default: '/tmp'
#!                         Optional
#! @input service_name: The service name
#!                      Default: 'postgresql-10'
#!
#! @output  return_result: STDOUT of the remote machine in case of success or the cause of the error in case of exception
#! @output  return_code: '0' if success, '-1' otherwise
#! @output  exception: contains the stack trace in case of an exception
#!
#! @result SUCCESS: Operation was executed successfully
#! @result FAILURE: There was an error
#!!#
########################################################################################################################

namespace: io.cloudslang.postgresql

imports:
  base: io.cloudslang.base.cmd
  ssh: io.cloudslang.base.ssh
  remote: io.cloudslang.base.remote_file_transfer
  folders: io.cloudslang.base.os.linux.folders
  groups: io.cloudslang.base.os.linux.groups
  users: io.cloudslang.base.os.linux.users
  strings: io.cloudslang.base.strings
  utils: io.cloudslang.base.utils
  postgres: io.cloudslang.postgresql

flow:
  name: postgres_operation

  inputs:
    - hostname:
        required: true
    - username:
        sensitive: true
    - password:
        default: ''
        required: false
        sensitive: true
    - proxy_host:
        required: false
    - proxy_port:
        required: false
    - proxy_username:
        required: false
    - proxy_password:
        required: false
    - connection_timeout:
        default: '10000'
    - execution_timeout:
        default: '90000'
    - installation_location:
        default: '/var/lib/pgsql/10'
    - operation:
        required: false
    - start_on_boot:
        required: false
    - private_key_file:
        required: false
    - pg_ctl_location:
        default: '/usr/pgsql-10/bin'
        required: false
    - service_name:
        default: 'postgresql-10'

  workflow:
    - check_installation_path:
        do:
          ssh.ssh_flow:
            - host: ${hostname}
            - port: '22'
            - username
            - private_key_file
            - proxy_host
            - proxy_port
            - proxy_username
            - proxy_password
            - timeout: ${execution_timeout}
            - connect_timeout: ${connection_timeout}
            - command: >
                ${'sudo -u postgres [ -d ' + installation_location + ' ] && echo "true" || echo "false"'}
        publish:
          - return_result
          - standard_out
        navigate:
          - SUCCESS: verify_installation_path
          - FAILURE: FAILURE

    - verify_installation_path:
        do:
          strings.string_occurrence_counter:
            - string_in_which_to_search: ${standard_out}
            - string_to_find: 'true'
        publish:
          - return_result: ${'Installation location was not found'}
        navigate:
          - SUCCESS: check_operation_value
          - FAILURE: FAILURE

    - check_operation_value:
        do:
           utils.is_null:
            - variable: ${operation}
        navigate:
          - IS_NULL: check_start_on_boot_value
          - IS_NOT_NULL: run_command

    - run_command:
       do:
         ssh.ssh_flow:
           - host: ${hostname}
           - port: '22'
           - username
           - private_key_file
           - proxy_host
           - proxy_port
           - proxy_username
           - proxy_password
           - timeout: ${execution_timeout}
           - connect_timeout: ${connection_timeout}
           - command: >
               ${'sudo -i -u postgres ' + pg_ctl_location + '/pg_ctl -s -D ' + installation_location + '/data ' + operation + ' > /dev/null'}
       publish:
         - return_result
         - exception: ${standard_err}
         - return_code

    - check_start_on_boot_value:
        do:
           utils.is_null:
            - variable: ${start_on_boot}
        navigate:
          - IS_NULL: SUCCESS
          - IS_NOT_NULL: run_start_on_boot

    - run_start_on_boot:
        do:
           utils.is_true:
            - bool_value: ${start_on_boot}
        navigate:
          - 'TRUE': enable_start_on_boot
          - 'FALSE': disable_start_on_boot

    - enable_start_on_boot:
       do:
         ssh.ssh_flow:
           - host: ${hostname}
           - port: '22'
           - username
           - private_key_file
           - proxy_host
           - proxy_port
           - proxy_username
           - proxy_password
           - timeout: ${execution_timeout}
           - connect_timeout: ${connection_timeout}
           - command: >
               ${'sudo systemctl enable ' + service_name}
       publish:
         - return_result
         - exception: ${standard_err}
         - return_code
       navigate:
         - SUCCESS: SUCCESS
         - FAILURE: FAILURE

    - disable_start_on_boot:
       do:
         ssh.ssh_flow:
           - host: ${hostname}
           - port: '22'
           - username
           - private_key_file
           - proxy_host
           - proxy_port
           - proxy_username
           - proxy_password
           - timeout: ${execution_timeout}
           - connect_timeout: ${connection_timeout}
           - command: >
               ${'sudo systemctl disable ' + service_name}
       publish:
        # Disable str_err: if success then Removed symlink /etc/systemd/system/multi-user.target.wants/postgresql-10.service.
         - return_result
         - return_code
         - exception
       navigate:
         - SUCCESS: SUCCESS
         - FAILURE: FAILURE

  outputs:
    - return_result
    - exception
    - command_return_code
    - return_code
  results:
    - SUCCESS
    - FAILURE

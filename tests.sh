#!/usr/bin/env bash

# Purpose : Test the tested scripts
# Author  : Ky-Anh Huynh
# License : Public domain

_gk8s() {
  "$(pwd -P)"/gk8s "${@}"
}

_fail_issue_6_with_empty_cluster_name() {
  _gk8s ''
}

_fail_without_any_argument() {
  _gk8s
}

_fail_with_wrong_cluster_prefix() {
  _gk8s local
}

_ok_with_local_and_without_any_argument() {
  _gk8s :local
}

_fail_when_command_not_found() {
  _gk8s :any_name -- foo/bar xyz
}

# NOTE: helm command is required.
_fail_with_helm_repo_list() {
  (
    export HELM_REPOSITORY_CONFIG=/dev/null
    touch ~/.config/gk8s/helm_test
    _gk8s :helm_test helm repo list
  )
}

# NOTE: kubectl command is required.
_fail_with_cluster_config_not_found() {
  (
    # shellcheck disable=SC2030
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :localzzzzz get pods
  )
}

_fail_with_local_and_cluster_config_not_found() {
  _gk8s :local get pods
}

_fail_with_fake_kubectl_get_pods_with_dashes_way() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :foobar -- get pods
  )
}

_ok_with_fake_kubectl_get_pods_with_dashes_way() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :foobar -- echo get pods
  )
}

_ok_with_fake_kubectl_get_pods() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :foobar get pods
  )
}

_ok_with_fake_kubectl_get_pods_with_kubectl_explicitly() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :foobar kubectl get pods
  )
}

_fail_to_delete() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH
    _gk8s :foobar delete pods
  )
}

_ok_to_delete() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH

    touch .delete
    _gk8s :foobar delete pods
  )
}

_ok_to_delete_with_env_flag() {
  (
    touch ~/.config/gk8s/foobar
    # shellcheck disable=SC2030
    # shellcheck disable=SC2031
    PATH="$(pwd -P)":$PATH
    export PATH

    DELETE=true _gk8s :foobar delete pods
  )
}

# $1: function to test
# $2: regular expression
# $*: Test description
_test() {
  fun="$1"; shift
  reg="$1"; shift

  >&2 echo "::"
  >&2 echo ":: ${fun}: $*"
  >&2 echo ":: ${fun}: expecting '$reg'"

  _f_output="${fun}.tmp"
  "${fun}" > "$_f_output" 2>&1
  ret="$?"
  if grep -sqEe "$reg" -- "$_f_output"; then
    >&2 echo ":: PASSED: ${fun}"
  else
    >&2 echo ":: FAILED: ${fun}"
    < "$_f_output" awk '{printf(":: (output) %s\n", $0)}'
    (( errors++ ))
  fi

  if [[ "$fun" =~ _fail.* ]]; then
    [[ "$ret" -ge 1 ]] \
    || { >&2 echo ":: FAILED: ${fun}: Return code must be >= 1"; (( errors++ )); }
  else
    [[ "$ret" -eq 0 ]] \
    || { >&2 echo ":: FAILED: ${fun}: Return code must be 0"; (( errors++ )); }
  fi
}

default() {
  ln -sfv /bin/true kubectl
  mkdir -pv ~/.config/gk8s

  _test _fail_when_command_not_found \
      "Command not found" \
      "Exit immediately when requested kubectl command is not found."

  _test _fail_issue_6_with_empty_cluster_name \
      "Error: Cluster name must be something like :foo" \
      "#6: Cluster name must not be empty."

  _test _fail_with_wrong_cluster_prefix \
      "must be prefixed with" \
      "Return error when cluster name is not started with :"

  _test _fail_without_any_argument \
      "Cluster name.*is required." \
      "Return error when nothing is specified at command line."

  _test _ok_with_local_and_without_any_argument \
      "noop command does nothing" \
      "The noop command just does nothing"

  _test _fail_with_cluster_config_not_found \
      "KUBECONFIG file not found:" \
      "Return immediately when kubecfg file not found."

  _test _fail_with_local_and_cluster_config_not_found \
      "(Command not found)|(KUBECONFIG file not found:)|(The connection to the server localhost:8080 was refused)" \
      "Return when cluster configuration doesn't work"

  _test _ok_with_fake_kubectl_get_pods \
      "Executing.*kubectl get pods.*KUBECONFIG:.*foobar" \
      "Ok when there is a simple get pods command"

  _test _ok_with_fake_kubectl_get_pods_with_kubectl_explicitly \
      "Executing.*kubectl get pods.*KUBECONFIG:.*foobar" \
      "Ok when kubectl command is aslo provided"

  _test _fail_with_fake_kubectl_get_pods_with_dashes_way \
      "Command not found get" \
      "Fail if raw command is not found."

  _test _ok_with_fake_kubectl_get_pods_with_dashes_way \
      "echo get pods" \
      "Fail if raw command is not found."

  _test _fail_to_delete \
      "File .delete does.* exist" \
      "Fail to delete because .delete file not found."

  _test _ok_to_delete \
      "File .delete was removed." \
      "Flag file will be removed first."

  _test _ok_to_delete \
      "Executing.*kubectl delete pods" \
      "Now executing actual delete command."

  _test _ok_to_delete_with_env_flag \
      "Executing.*kubectl delete pods" \
      "Now executing actual delete command."

  _test _fail_with_helm_repo_list \
      "Error: no repositories to show" \
      "helm would not need any separator (--). To get this test passed,
      helm binary should be found on your local system."
}

### main routines ######################################################

set -u
errors=0

"${@:-_panic}"

>&2 echo "::"
>&2 echo ":: ${errors} test(s) failed."
[[ "${errors}" -eq 0 ]]

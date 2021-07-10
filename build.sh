#!/bin/sh

# get self context
self="$(realpath "${0}")"
dir="$(dirname "${self}")"

# set the options' default values
tag="jlisher/php56-phalcon-2-dev:latest"
dockerfile="Dockerfile"

getClient() {
  if command -v docker >/dev/null; then
    command -v docker
    return 0
  fi

  if command -v podman >/dev/null; then
    command -v podman
    return 0
  fi

  echo "No container client found! Please install either the docker cli or podman."
  exit 1
}

build() {
  "$(getClient)" build --tag "${tag}" --file "${dockerfile}" "${dir}"
  return $?
}

parseInput() {
  while [ -n "${1}" ] && [ "${1}" != "--" ]; do
    case "${1}" in
    -h | --help)
      cat <<EOF
Simple script to build the image.

Usage:
${0} [OPTIONS]

OPTIONS:
  -h, --help        print this and exit.
  -t, --tag         Set the tag to be used for the image.
  -f, --file        The path to the Dockerfile to build.
      --dockerfile
EOF
      ;;
    -t | --tag)
      tag="${2}"
      shift
      shift
      ;;

    -f | --file | --dockerfile)
      dockerfile="${2}"
      shift
      shift
      ;;
    *)
      shift
      ;;
    esac
  done
}

parseInput "${@}"
build

exit $?

#!/usr/bin/env bash
set -Eeuo pipefail

dam preset fullstack
dam daily add projectdoctor 'Check Laravel project'
dam daily add myroutes 'Show Laravel routes'
dam daily add qa 'Run quality pipeline'
dam list

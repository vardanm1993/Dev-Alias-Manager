#!/usr/bin/env bash
set -Eeuo pipefail

dam preset fullstack
dam daily add sail 'Run Sail directly'
dam daily add sailup 'Start Sail'
dam daily add projectdoctor 'Check Laravel project'
dam daily add myroutes 'Show Laravel routes'
dam daily add qa 'Run quality pipeline'
dam list

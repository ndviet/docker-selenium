#!/bin/bash
set -e

_log () {
    if [[ "$*" == "ERROR:"* ]] || [[ "$*" == "WARNING:"* ]] || [[ "${CONTAINER_LOGS_QUIET}" == "" ]]; then
        echo "$@"
    fi
}

if [ "${SE_DOWNLOAD_DIR}" != "${HOME}/Downloads" ]; then
    MKDIR_EXTRA=${SE_DOWNLOAD_DIR}","${MKDIR_EXTRA}
fi

CHOWN_EXTRA=${MKDIR_EXTRA}","${CHOWN_EXTRA}

if [ -n "${MKDIR_EXTRA}" ]; then
    for extra_dir in $(echo "${MKDIR_EXTRA}" | tr ',' ' '); do
        _log "Creating directory ${extra_dir} ${MKDIR_EXTRA_OPTS:+(mkdir options: ${MKDIR_EXTRA_OPTS})}"
        # shellcheck disable=SC2086
        mkdir ${MKDIR_EXTRA_OPTS:-"-p"} "${extra_dir}"
    done
fi

if [ -n "${CHOWN_EXTRA}" ]; then
    for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
        _log "Changing ${extra_dir} ownership. Ensure ${extra_dir} is owned by ${SEL_USER} ${CHOWN_EXTRA_OPTS:+(chown options: ${CHOWN_EXTRA_OPTS})}"
        fix-permissions "${extra_dir}"
    done
fi

# Raise warning if the user isn't able to write files to extra dirs
if [ -n "${CHOWN_EXTRA}" ]; then
    for extra_dir in $(echo "${CHOWN_EXTRA}" | tr ',' ' '); do
        if [[ ! -w ${extra_dir} ]]; then
            _log "WARNING: no write access to dir ${extra_dir}. Please correct the permissions manually (or run with --user root) once then start again with non-root user."
        else
            _log "Verified dir ${extra_dir} has write access."
        fi
    done
fi

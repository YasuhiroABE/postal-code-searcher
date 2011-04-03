#!/bin/bash
#
#  Copyright (C) 2010,2011 Yasuhiro ABE <yasu@yasundial.org>
#  Licensed under the Creative Commons License, "CC BY 3.0".
#

BASEDIR="$(dirname $0)"
TMPFILE="$(mktemp /tmp/replrubycmd.XXXXXXXXXX)"

echo "using temporary file: ${TMPFILE}"

function help () {
  echo ""
  echo "Usage: $0 ruby"
  echo ""
  echo "   Rewrite the ruby command path in each script file."
  echo ""
  echo "  Example: $0 ruby1.9"
  echo "  Example: $0 /usr/local/bin/ruby"
  echo ""
}

## check given argument
if test $# -ne 1 ; then
  help
  rm "${TMPFILE}"
  exit 1
fi

RUBY_COMMAND_PATH="$1"

if test -f "${RUBY_COMMAND_PATH}" ; then
  RUBY_COMMAND_PATH="${RUBY_COMMAND_PATH}"
else
  RUBY_COMMAND_PATH="$(which ${RUBY_COMMAND_PATH})"
fi

if test ! -f "${RUBY_COMMAND_PATH}" ; then
  echo ""
  echo "[error] ${RUBY_COMMAND_PATH} not found"
  help
  exit 1
fi

echo ""
echo "Selected ruby command name: ${RUBY_COMMAND_PATH}"
echo ""

## rewrite command name
for script in "${BASEDIR}/../utils/bin/"* "${BASEDIR}/../utils/sbin/"* "${BASEDIR}/../../../../contents/postal/"*.fcgi
do
  if (head -1 "${script}" | grep "/usr/bin/env" > /dev/null) ; then
    echo "writing script: ${script} "
    echo "#!/usr/bin/env ${RUBY_COMMAND_PATH}" > "${TMPFILE}"
    sed -e '/^#!\/usr\/bin\/env/d' "${script}" >> "${TMPFILE}"

    cp "${TMPFILE}" "${script}"
  fi
done

echo "finished."
test -f "${TMPFILE}" && rm "${TMPFILE}"

exit

## fin. ##

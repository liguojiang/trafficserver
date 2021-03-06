#! /usr/bin/env bash
#
#  Simple wrapper to run clang-format on a bunch of files
#
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

set -e # exit on error

DIR=${1:-.}
ROOT=${ROOT:-$(cd $(dirname $0) && git rev-parse --show-toplevel)/.git/fmt}
PACKAGE="clang-format-20160415.tar.bz2"
VERSION="clang-format version 3.9.0 (trunk 265913)"

URL=${URL:-https://bintray.com/artifact/download/apache/trafficserver/${PACKAGE}}

TAR=${TAR:-tar}
CURL=${CURL:-curl}

# default to using native sha1sum command when available
if [ $(which sha1sum) ] ; then
  SHASUM=${SHASUM:-sha1sum}
else
  SHASUM=${SHASUM:-shasum}
fi

ARCHIVE=$ROOT/$(basename ${URL})

case $(uname -s) in
Darwin)
  FORMAT=${FORMAT:-${ROOT}/clang-format/clang-format.osx}
  ;;
Linux)
  FORMAT=${FORMAT:-${ROOT}/clang-format/clang-format.linux}
  ;;
*)
  echo "Leif needs to build a clang-format for $(uname -s)"
  exit 2
esac

mkdir -p ${ROOT}

# Note that the two spaces between the hash and ${ARCHIVE) is needed
if [ ! -e ${FORMAT} -o ! -e ${ROOT}/${PACKAGE} ] ; then
  ${CURL} -L --progress-bar -o ${ARCHIVE} ${URL}
  ${TAR} -x -C ${ROOT} -f ${ARCHIVE}
  cat > ${ROOT}/sha1 << EOF
d5558924377a6ad5799956cec5b37d4e421e2156  ${ARCHIVE}
EOF
  ${SHASUM} -c ${ROOT}/sha1
  chmod +x ${FORMAT}
fi


# Make sure we only run this with our exact version
ver=$(${FORMAT} --version)
if [ "$ver" != "$VERSION" ]; then
    echo "Wrong version of clang-format!"
    echo "See https://bintray.com/apache/trafficserver/clang-format-tools/view for a newer version,"
    echo "or alternatively, undefine the FORMAT environment variable"
    exit 1
else
    for file in $(find $DIR -iname \*.[ch] -o -iname \*.cc); do
	echo $file
	${FORMAT} -i $file
    done
fi

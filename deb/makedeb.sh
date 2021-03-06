#!/bin/bash
# Copyright 2017 Frank Breedijk
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

UPSTREAM_VERSION=$1
COMMITS=$2
if [ -z $VERSION ]; then
    echo "Trying to determine version and commit count from git"
    FULLVERSION=$(git describe)
    UPSTREAM_VERSION=$(echo $FULLVERSION|sed 's/\-.*//')
    COMMITS=$(echo $FULLVERSION|sed 's/^[0-9\.]*\-//'|sed 's/\-.*//')
fi

[ -z $UPSTREAM_VERSION ] && echo "We need a version number as first argument" && exit
[ -z $COMMITS ] && echo "We a commit count as second argument" && exit

VERSION="$UPSTREAM_VERSION.$COMMITS"
DIR="/tmp/seccubus-$UPSTREAM_VERSION"


[ ! -d build ] && mkdir build
[ -d $DIR ] && rm -rf $DIR

echo "Copying files"
mkdir $DIR
cd $DIR
(cd /root/project;tar -cf - --exclude \"tmp/*\" *)|tar -xf -
echo "Building"
[ -d debian ] && rm -rf debian
mkdir debian
for f in $(ls deb); do
    NEWNAME=${f/#debian./}
    case $NEWNAME in
        changelog)
            < deb/$f sed s/\(0\.0\.0\-0\)/\($UPSTREAM_VERSION-$COMMITS\)/ > debian/$NEWNAME
            ;;
        seccubus.dsc)
            < deb/$f sed "s/Version\: .*/Version\: $VERSION/" > debian/$NEWNAME
            ;;
        *)
            ln -s $DIR/deb/$f debian/$NEWNAME
            ;;
    esac
done
dpkg-buildpackage
dpkg-deb --build debian/seccubus /root/project/build

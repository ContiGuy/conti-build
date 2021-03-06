#!/bin/bash
#
# Copyright © 2016 - present:  Conti Guy  <mrcs.contiguy@mailnull.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# wrapper script for running some development tools inside a docker container
#
# see https://github.com/ContiBuild/conti-build
#

# don't change this! - needed if docker needs to be run via sudo
# SUDO=sudo

#~ DOCKER_IMAGE_GOBASE="conti-guy/conti-build.base"
#~ DOCKER_IMAGE_GOTOOLS="conti-guy/conti-build"
DOCKER_IMAGE_GO="conti-guy/conti-build.go"
DOCKER_IMAGE_ELM="conti-guy/conti-build.elm"
if $(echo $* | grep elm > /dev/null) ; then
	DOCKER_IMAGE="${CB_DOCKER_IMAGE:-$DOCKER_IMAGE_ELM}"
else
	DOCKER_IMAGE="${CB_DOCKER_IMAGE:-$DOCKER_IMAGE_GO}"
fi

##SCR_DIR=/source

if which cobui > /dev/null; then :
else
	echo "Please make sure the 'cobui' tool created by conti-build/setup.sh is in your PATH!"
	exit 23
fi

function getwd ()
{
	if PwdCmd=$(which pwd) ; then
		"$PwdCmd"
	else
		pwd
	fi
}


if GOBASE=$(cobui gopath --base 2>/dev/null) && GOPKG=$(cobui gopath --package 2>/dev/null) ; then
	V="-v $GOBASE:/go"
	# W="-w /go/src/$GOPKG"
else
	# WD="$(pwd)"
	WD="$(getwd)"
	GOPKG="$(basename $WD)"
	# SCR_DIR="/go/src/$GOPKG"

#	echo "Please make sure your source code is in the current directory and is in a proper Go workspace and the GOPATH environment variable is set correctly"
#	exit 29

	# V="-v $(pwd):/go/src/$GOPKG"
	V="-v $(getwd):/go/src/$GOPKG"
	# VBIN="-v $(pwd):/go/bin"
	XBIN="/tmp/conti-build/bin"
	mkdir -p "$XBIN"
	VBIN="-v $XBIN:/go/bin"
	# W="-w $SCR_DIR"
fi
##SCR_DIR="/go/src/$GOPKG"
W="-w /go/src/$GOPKG"

DEV_HOME="/home/developer"
VHOME="-v $HOME:$DEV_HOME"
EHOME="-e HOME=$DEV_HOME"

#if echo "$*" | grep -e "^elm " -e "^psc " -e "^pulp " -e "^bower "  > /dev/null ; then
#	V="-v $(pwd):$SCR_DIR"
#	W="-w $SCR_DIR"
#else
#	if GOBASE=$(cobui gopath --base) && GOPKG=$(cobui gopath --package) ; then
#		V="-v $GOBASE:/go"
#		W="-w /go/src/$GOPKG"
#	else
#		echo "Please make sure your source code is in the current directory and is in a proper Go workspace and the GOPATH environment variable is set correctly"
#		exit 29
#	fi
#fi


if [ "XX$http_proxy" != "XX" ] ; then
PROXY="-e HTTP_PROXY=$http_proxy \
	-e http_proxy=$http_proxy \
	-e HTTPS_PROXY=$http_proxy \
	-e https_proxy=$http_proxy"
fi

# -p 8888:8000
#	-p 6080:8000 \
#	-p 6060:6060 \
#	-w "$WD"
#	$V1 $V2 $W \

if echo "$*" | grep -e elm | grep -e reactor > /dev/null ; then
	PORTS="$PORTS $(cobui port 8000)"
fi
if echo "$*" | grep -e go | grep -e doc | grep -e '-http=:' > /dev/null ; then
	godocPort=$(echo "$*" | sed -e 's/.*-http=://' -e 's/[^0-9]*//')
	PORTS="$PORTS $(cobui port $godocPort)"
fi

$SUDO docker run         \
	-t --rm              \
	$V $VBIN $W          \
	$VHOME               \
	$EHOME               \
	$PROXY               \
	$PORTS               \
	-u $(id -u):$(id -g) \
	$CB_DOCKER_RUN_OPTS  \
	"$DOCKER_IMAGE"      \
	"$@"


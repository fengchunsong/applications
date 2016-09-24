#!/bin/bash

. ${APP_ROOT}/toolset/setup/basic_cmd.sh

######################################################################################
# Notes:
#  To build tcprstat
#
#####################################################################################

BUILD_DIR="./"$(tool_get_build_dir $1)
SERVER_FILENAME=$1
TARGET_DIR=$(tool_get_first_dirname ${BUILD_DIR})

####################################################################################
# Prepare for build
####################################################################################
if [ $(tool_check_exists "${BUILD_DIR}/${TARGET_DIR}/src/tcprstat") == 0 ] ; then
    echo "tcprstat has been built, so do nothing"
    echo "Build tcprstat successfully"
    exit 0 
fi

sudo rm -fr ${BUILD_DIR}/${TARGET_DIR}*
mkdir -p ${BUILD_DIR}
tar -zxvf ${SERVER_FILENAME} -C ${BUILD_DIR}
TARGET_DIR=$(tool_get_first_dirname ${BUILD_DIR})

if [ -z "${TARGET_DIR}" ] ; then
    echo "Fail to get any directory under ${BUILD_DIR}"
    exit 1
fi

#Replace libpcap1.1 with libpcap1.6 in order to support ARM64 platform
#if [ $(uname -m) == "aarch64" ] ; then
    echo "Replace libpcap1.1 with libpcap1.6 in order to support arm64 platform"
    tool_download -o libpcap-1.6.1.tar.gz http://www.tcpdump.org/release/libpcap-1.6.1.tar.gz
    cp libpcap-1.6.1.tar.gz ${BUILD_DIR}/${TARGET_DIR}/libpcap/
    rm ${BUILD_DIR}/${TARGET_DIR}/libpcap/libpcap-1.1.1.tar.gz
    chmod 755 ${BUILD_DIR}/${TARGET_DIR}/libpcap/resolver-patch
    sed -i "s/libpcap-1.1.1/libpcap-1.6.1/g"  ${BUILD_DIR}/${TARGET_DIR}/libpcap/resolver-patch
#fi

echo "Finish build preparation......"

######################################################################################
# Build TcpRstat
#####################################################################################
#Build Step 1: auto generation
pushd ${BUILD_DIR} > /dev/null
cd ${TARGET_DIR}/

CONFIGURE_OPTIONS=""
if [ $(uname -m) == "aarch64" ] ; then
    CONFIGURE_OPTIONS=${CONFIGURE_OPTIONS}" -build=arm "
fi

chmod 755 bootstrap
./bootstrap
./configure ${CONFIGURE_OPTIONS}
make

if [ $(tool_check_exists /usr/bin/tcprstat-static) == 0 ]; then
    echo "tcpstat-static has been installed "
else 
    sudo cp ./src/tcprstat-static /usr/bin/tcprstat-static
    sudo cp ./src/tcprstat /usr/bin/tcprstat
fi

sudo chmod u+s /usr/bin/tcprstat
sudo chmod u+s /usr/bin/tcprstat-static

popd > /dev/null

echo "**********************************************************************************"
echo "Build tcprstat completed"


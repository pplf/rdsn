#!/bin/bash

# check_and_download package_name url md5sum extracted_folder_name
# return:
#   0 if download and extract ok
#   1 if already downloaded
#   2 if download or extract fail
function check_and_download()
{
    package_name=$1
    url=$2
    correct_md5sum=$3
    extracted_folder_name=$4
    if [ -f $package_name ]; then
        echo "$package_name has already downloaded, skip it"

        if [ -d $extracted_folder_name ]; then
            echo "$package_name has been extracted"
            return 1
        else
            echo "extract package $package_name"
            extract_package $package_name
            local ret_code=$?
            if [ $ret_code -ne 0 ]; then
                return 2
            else
                return 0
            fi
        fi
    else
        echo "download package $package_name"
        curl -L $url > $package_name
        local ret_code=$?
        if [ $ret_code -ne 0 ]; then
            rm -f $1
            echo "package $package_name download failed"
            return 2
        fi

        md5=`md5sum $1 | cut -d ' ' -f1`
        if [ "$md5"x != "$correct_md5sum"x ]; then
            rm -f $1
            echo "package $package_name is broken, already deleted"
            return 2
        fi

        extract_package $package_name
        local ret_code=$?
        if [ $ret_code -ne 0 ]; then
            return 2
        else
            return 0
        fi
   fi
}

function extract_package()
{
    package_name=$1
    is_tar_gz=$(echo $package_name | grep ".tar.gz")
    if [[ $is_tar_gz != "" ]]; then
        tar xf $package_name
    fi
    is_zip=$(echo $package_name | grep ".zip")
    if [[ $is_zip != "" ]]; then
        unzip -oq $package_name
    fi
    local ret_code=$?
    if [ $ret_code -ne 0 ]; then
        rm -f $package_name
        echo "extract $package_name failed, please delete the incomplete folder"
        return 2
    else
        return 0
    fi
}

function exit_if_fail()
{
    if [ $1 -eq 2 ]; then
        exit $1
    fi
}


TP_DIR=$( cd $( dirname $0 ) && pwd )
TP_SRC=$TP_DIR/src
TP_BUILD=$TP_DIR/build
TP_OUTPUT=$TP_DIR/output

if [ ! -d $TP_SRC ]; then
    mkdir $TP_SRC
fi

if [ ! -d $TP_BUILD ]; then
    mkdir $TP_BUILD
fi

if [ ! -d $TP_OUTPUT ]; then
    mkdir $TP_OUTPUT
fi

cd $TP_SRC
# concurrent queue
check_and_download "concurrentqueue-v1.0.0-beta.tar.gz"\
    "https://codeload.github.com/cameron314/concurrentqueue/tar.gz/v1.0.0-beta"\
    "761446e2392942aa342f437697ddb72e"\
    "concurrentqueue-1.0.0-beta"
exit_if_fail $?

# googletest
check_and_download "googletest-1.8.0.tar.gz"\
    "https://codeload.github.com/google/googletest/tar.gz/release-1.8.0"\
    "16877098823401d1bf2ed7891d7dce36"\
    "googletest-release-1.8.0"
exit_if_fail $?

# gperftools
check_and_download "gperftools-2.7.tar.gz"\
    "https://github.com/gperftools/gperftools/releases/download/gperftools-2.7/gperftools-2.7.tar.gz"\
    "c6a852a817e9160c79bdb2d3101b4601"\
    "gperftools-2.7"
exit_if_fail $?

#rapidjson
check_and_download "rapidjson-v1.1.0.tar.gz"\
    "https://codeload.github.com/Tencent/rapidjson/tar.gz/v1.1.0"\
    "badd12c511e081fec6c89c43a7027bce"\
    "rapidjson-1.1.0"
exit_if_fail $?

# thrift 0.9.3
check_and_download "thrift-0.9.3.tar.gz"\
    "http://archive.apache.org/dist/thrift/0.9.3/thrift-0.9.3.tar.gz"\
    "88d667a8ae870d5adeca8cb7d6795442"\
    "thrift-0.9.3"
ret_code=$?
if [ $ret_code -eq 2 ]; then
    exit 2
elif [ $ret_code -eq 0 ]; then
    echo "make patch to thrift"
    cd thrift-0.9.3
    patch -p1 < ../../fix_thrift_for_cpp11.patch
    if [ $? != 0 ]; then
        echo "ERROR: patch fix_thrift_for_cpp11.patch for thrift failed"
        exit 2
    fi
    cd ..
fi

# use zookeeper c client
check_and_download "zookeeper-3.4.10.tar.gz"\
    "http://ftp.jaist.ac.jp/pub/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz"\
    "e4cf1b1593ca870bf1c7a75188f09678"\
    "zookeeper-3.4.10"
exit_if_fail $?

# libevent for send http request
check_and_download "libevent-2.1.8.tar.gz"\
    "https://github.com/libevent/libevent/archive/release-2.1.8-stable.tar.gz"\
    "80f8652e4b08d2ec86a5f5eb46b74510"\
    "libevent-release-2.1.8-stable"
exit_if_fail $?

# poco 1.7.8
check_and_download "poco-1.7.8.tar.gz"\
    "https://codeload.github.com/pocoproject/poco/tar.gz/poco-1.7.8-release"\
    "4dbf02e14b9f20940ca0e8c70d8f6036"\
    "poco-poco-1.7.8-release"
exit_if_fail $?

# fds
if [ ! -d $TP_SRC/fds ]; then
    git clone https://github.com/XiaoMi/galaxy-fds-sdk-cpp.git
    if [ $? != 0 ]; then
        echo "ERROR: download fds wrong"
        exit 2
    fi
    echo "mv galaxy-fds-sdk-cpp fds"
    mv galaxy-fds-sdk-cpp fds
else
    echo "fds has already downloaded, skip it"
fi

# fmtlib
check_and_download "fmt-4.0.0.tar.gz"\
    "https://codeload.github.com/fmtlib/fmt/tar.gz/4.0.0"\
    "c9be9a37bc85493d1116b0af59a25eba"\
    "fmt-4.0.0"
exit_if_fail $?

# gflags
check_and_download "gflags-2.2.1.zip"\
    "https://github.com/gflags/gflags/archive/v2.2.1.zip"\
    "2d988ef0b50939fb50ada965dafce96b"\
    "gflags-2.2.1"
exit_if_fail $?

# s2geometry
check_and_download "s2geometry-0239455c1e260d6d2c843649385b4fb9f5b28dba.zip"\
    "https://github.com/google/s2geometry/archive/0239455c1e260d6d2c843649385b4fb9f5b28dba.zip"\
    "bfa5f1c08f535a72fb2c92ec16332c64"\
    "s2geometry-0239455c1e260d6d2c843649385b4fb9f5b28dba"
ret_code=$?
if [ $ret_code -eq 2 ]; then
    exit 2
elif [ $ret_code -eq 0 ]; then
    echo "make patch to s2geometry"
    cd s2geometry-0239455c1e260d6d2c843649385b4fb9f5b28dba
    patch -p1 < ../../fix_s2_for_pegasus.patch
    if [ $? != 0 ]; then
        echo "ERROR: patch fix_s2_for_pegasus.patch for s2geometry failed"
        exit 2
    fi
    cd ..
fi

cd $TP_DIR

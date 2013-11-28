#!/bin/sh

#function get_abs_path {
#    dir=$(cd `dirname $1` >/dev/null; pwd )
#    echo $dir
#}
#
#abs=`get_abs_path ./deploy/static`
#echo $abs
#
#
# Split filenames..
#
#fullfile=$1
#filename=$(basename "$fullfile")
#extension="${filename##*.}"
#filename="${filename%.*}"

srcdir=`dirname $0`
srcdir=`cd $srcdir; pwd`
dstdir=`pwd`

echo "Fetching logstash"
# curl -L https://download.elasticsearch.org/logstash/logstash/logstash-1.2.2-flatjar.jar -o ./lib/logstash.jar
cp ./scripts/logstash.jar ./lib
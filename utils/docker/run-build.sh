#!/usr/bin/env bash
#
# Copyright 2019, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# run-build.sh <pmemkv_version> - checks binding's building and installation with
#								pmemkv installed in given version
#

PREFIX=/usr

set -e

# build and install pmemkv
cd ~
pmemkv_version=$1
git clone https://github.com/pmem/pmemkv.git
cd pmemkv
git checkout $pmemkv_version
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_INSTALL_PREFIX=$PREFIX
make -j2
echo $USERPASS | sudo -S make install

echo
echo "################################################################"
echo "### Verifying building and installing of the pmemkv-ruby binding"
echo "################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-ruby.git
cd pmemkv-ruby
mkdir -p vendor/cache/
echo $USERPASS | sudo -S mv /opt/bindings/ruby/* vendor/cache/
bundle install --local
bundle exec rspec

echo
echo "################################################################"
echo "### Checking example from pmemkv-tools"
echo "################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-tools.git
cd pmemkv-tools
make example_ruby

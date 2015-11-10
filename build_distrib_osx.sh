#!/bin/sh

set -e

rm -f ybapp.tar.gz
rm -rf ybapp_osx
stack build
mkdir -p ybapp_osx
cp .stack-work/install/x86_64-osx/lts-3.8/7.10.2/bin/ybapp ybapp_osx/ybapp.command
cp README.txt ybapp_osx/
tar -czf ybapp.tar.gz ybapp_osx

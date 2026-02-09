#!/bin/bash
cd "$(dirname "$0")/../.."

fail()
{
       echo "FAIL $@"
       exit 1
}
export CXXFLAGS="$CXXFLAGS -std=c++11"
bash bootstrap/scripts/linux.sh --rebuild --deb --without-cli || fail main
bash bootstrap/appImage/deploy.sh

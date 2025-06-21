#!/usr/bin/env bash

######################################################################
# 4) configure and build mhvtl module + cta
######################################################################

set -eu

# install mhvtl
function install_myvtl() {
   git clone https://github.com/markh794/mhvtl
   cd mhvtl/
   make
   make install
   cd kernel
   make
   make install
   systemctl enable mhvtl.target 
   systemctl start mhvtl.target 
   systemctl status mhvtl.target 
}
# install_myvtl

#export CTA_VERSION="v5.11.10.t1"
#SHA="2fecdecb30d7e5c0726a332d7570144b8c7162a0"

#echo "Building CTA $CTA_VERSION based on $SHA"
#X=`pwd`
#VER="v5.11.10.0-1"
#NAME="CTA-$VER"

# v5.11.10 tgz baut nicht, da divere Objekte nicht passen...
# /TR 2025-06-20
#/home/user/CTA-v5.11.10.0-1/build_srpm/RPM/BUILD/cta-0-1/scheduler/SchedulerDatabaseTest.cpp:61:44: error: expected class-name before '{' token
#   61 | class OStoreFixture : public cta::OStoreDB {
#      |                                            ^
#/home/user/CTA-v5.11.10.0-1/build_srpm/RPM/BUILD/cta-0-1/scheduler/SchedulerDatabaseTest.cpp:63:14: error: 'cta::OStoreDB' has not been declared
#   63 |   using cta::OStoreDB::OStoreDB;
#      |              ^~~~~~~~

#curl \
#  --output $NAME.tar.gz \
#  https://gitlab.cern.ch/cta/CTA/-/archive/$VER/$NAME.tar.gz
#tar xzf $NAME.tar.gz
#cd $NAME

#sudo cat > /var/lib/pgsql/data/pg_hba.conf <<EOF
## TYPE  DATABASE        USER            ADDRESS                 METHOD
#local   all             all                                     trust
#host    all             all             127.0.0.1/32            trust
#host    all             all             ::1/128                 trust
#EOF

# make a new blank repository in the current directory
mkdir -p $NAME
cd $NAME
git init
git remote add origin https://gitlab.cern.ch/cta/CTA.git/
git fetch origin $SHA
git reset --hard FETCH_HEAD

cat ~/patches/cta.spec.in.diff | patch -p1
cat ~/patches/zlib.diff | patch -p1

rm -rf "xrootd-ssi-protobuf-interface"
git clone https://gitlab.cern.ch/eos/xrootd-ssi-protobuf-interface.git/ \
  "xrootd-ssi-protobuf-interface"

rm -rf "eos_cta/grpc-proto"
git clone https://github.com/cern-eos/grpc-proto \
  "eos_cta/grpc-proto/protobuf"

rm -rf "catalogue/cta-catalogue-schema"
git clone https://gitlab.cern.ch/cta/cta-catalogue-schema.git/ \
  "catalogue/cta-catalogue-schema"

for i in `find . -name "*.[ch]pp"`; do
  sed -i 's|std::optional<std::uint|std::optional<uint|g' "$i"
done

mkdir -p build_srpm
cd build_srpm
cmake3 -DCTA_USE_PGSCHED=1 -DENABLE_CCACHE=1 -DDISABLE_ORACLE_SUPPORT=1 ../
make cta_srpm
make cta_rpm

#sudo yum-builddep -y --nogpgcheck build_srpm/RPM/SRPMS/*
#make -j3
exit

# reset cloud-init configuration and poweroff
sudo cloud-init clean --logs
sync && sleep 2 && sudo poweroff &

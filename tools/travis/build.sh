#!/bin/bash -x
# Build script for Travis-CI.

SCRIPTDIR=$(cd $(dirname "$0") && pwd)
ROOTDIR="$SCRIPTDIR/../../.."
WHISKDIR="$ROOTDIR/openwhisk"
PACKAGESDIR="$WHISKDIR/catalog/extra-packages"
IMAGE_PREFIX="testing"

# Set Environment
export OPENWHISK_HOME=$WHISKDIR

cd $WHISKDIR

tools/build/scanCode.py "$SCRIPTDIR/../.."

# Build Openwhisk
TERM=dumb ./gradlew \
:common:scala:install \
:core:controller:install \
:core:invoker:install \
:tests:install \
distDocker

cd $WHISKDIR/ansible

# Deploy Openwhisk
ANSIBLE_CMD="ansible-playbook -i environments/local"

$ANSIBLE_CMD setup.yml
$ANSIBLE_CMD prereq.yml
$ANSIBLE_CMD couchdb.yml
$ANSIBLE_CMD initdb.yml
$ANSIBLE_CMD wipe.yml
$ANSIBLE_CMD openwhisk.yml

cd $WHISKDIR

VCAP_SERVICES_FILE="$(readlink -f $WHISKDIR/../tests/credentials.json)"

#update whisk.properties to add tests/credentials.json file to vcap.services.file, which is needed in tests
WHISKPROPS_FILE="$WHISKDIR/whisk.properties"
sed -i 's:^[ \t]*vcap.services.file[ \t]*=\([ \t]*.*\)$:vcap.services.file='$VCAP_SERVICES_FILE':'  $WHISKPROPS_FILE
cat whisk.properties

WSK_CLI=$WHISKDIR/bin/wsk
AUTH_KEY=$(cat $WHISKDIR/ansible/files/auth.whisk.system)
EDGE_HOST=$(grep '^edge.host=' $WHISKPROPS_FILE | cut -d'=' -f2)

# Place this template in correct location to be included in packageDeploy
mkdir -p $PACKAGESDIR/preInstalled/ibm-functions
cp -r $ROOTDIR/WWCloudFunctions $PACKAGESDIR/preInstalled/ibm-functions/

# Install the deploy package
cd $PACKAGESDIR/packageDeploy/packages
source $PACKAGESDIR/packageDeploy/packages/installCatalog.sh $AUTH_KEY $EDGE_HOST $WSK_CLI

# Test
cd $ROOTDIR/WWCloudFunctions
./gradlew :tests:test

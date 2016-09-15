# Load utility functions
# Save script location so we can load script dependencies
pushd `dirname "$1"` > /dev/null
SWD=`pwd`
popd > /dev/null

export TARGET_LOCATION=/opt/ossim-1.9.0-src
source $SWD/resources/retrieval_functions
source $SWD/resources/build_functions
source $SWD/resources/release_version

# Load URLs for dependency code downloads
source $SWD/resources/omar_dependency_urls

# Load Config Change Functions
source $SWD/resources/config_changes

# Dependency Checker
source $SWD/resources/dependency_check

source $SWD/resources/files_and_dirs
source $SWD/resources/omar_dependency_urls


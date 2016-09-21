# Load utility functions
# Save script location so we can load script dependencies
pushd `dirname "$1"` > /dev/null
SWD=`pwd`
popd > /dev/null

export TARGET_LOCATION=/opt/ossim-1.9.0-src
# Load URLs for dependency code downloads
source $SWD/resources/retrieval_functions
source $SWD/resources/omar_dependency_urls
source $SWD/resources/kakadu_config
source $SWD/resources/mrsid_config
source $SWD/resources/files_and_dirs

export OSSIM_PREFS_FILE="${BUILD_LOCATION}/ossim_preferences"

#source $SWD/resources/release_version
#source $SWD/resources/build_functions

# Load Config Change Functions
#source $SWD/resources/config_changes

# Dependency Checker
#source $SWD/resources/dependency_check

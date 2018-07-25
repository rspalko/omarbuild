#!/bin/bash

# OMAR BUILD SCRIPT
# Tested with OMAR 1.8.19 on CentOS 6.6 and 7.1.1503
# upgraded to 1.9.0 and OSSIM Github (tested on CentOS 6.6 with devtoolset-2 for Kakadu required GCC)

# Set umask to avoid permission issues 
umask 0022

# Exit on error
set -e

# Save script location so we can load script dependencies
pushd `dirname "$0"` > /dev/null
SWD=`pwd`
popd > /dev/null

# Load utility functions
source $SWD/resources/retrieval_functions
source $SWD/resources/build_functions
source $SWD/resources/release_version

# Load URLs for dependency code downloads
source $SWD/resources/omar_dependency_urls
source $SWD/resources/kakadu_config
source $SWD/resources/mrsid_config

# Load Config Change Functions
source $SWD/resources/config_changes

# Dependency Checker
source $SWD/resources/dependency_check

checkOmar
checkDependencies
#checkMvapich2

# We should have JAVA now if we are still running
export JAVA=`which java`
JAVA_HOME=${JAVA_HOME:-`dirname $(dirname $JAVA)`}

# Ask for user input
clear
echo -e "Choose an Option Below by entering a number"
echo -e "\t1. Retrieve all internet dependencies and package for private network build."
echo -e "\t2. Build from packaged dependencies." 
echo -e "\t3. Retrieve and build on local server."
read -n 1 RUNOPTION

clear

if [ $RUNOPTION != "1" -a $RUNOPTION != "2" -a $RUNOPTION != "3" ]; then
  echo "Invalid Option Selected, exiting script"
  exit 1
fi

DEFAULT_TARGET_LOCATION=/opt/ossim-1.9.0-src
read -p "Select download/build location: (Default is $DEFAULT_TARGET_LOCATION): " TARGET_LOCATION
TARGET_LOCATION=${TARGET_LOCATION:-$DEFAULT_TARGET_LOCATION}

MARKER=.omarbuildmarker
 
# Setup commonly used variables for files and directories
source $SWD/resources/files_and_dirs

if [ $RUNOPTION -eq "1" -o $RUNOPTION -eq "3" ]; then

  if [ -d "$TARGET_LOCATION" ]; then
    if [ -e "$TARGET_LOCATION" -a ! -e "${TARGET_LOCATION}/${MARKER}" ]; then
      echo "DESTINATION TARGET LOCATION ALREADY EXISTS AT $TARGET_LOCATION, BUT DOES NOT CONTAIN AN OMAR BUILD"
      echo "PLEASE REMOVE OR SELECT ANOTHER LOCATION"
      echo "EXITING SCRIPT"
      exit 1
    fi
  fi

  DEFAULT_CACHE_LOCATION=/tmp/omardeps
  read -p "Select cache location for dependencies to avoid repeat downloads: (Default is $DEFAULT_CACHE_LOCATION): " CACHE_LOCATION
  CACHE_LOCATION=${CACHE_LOCATION:-$DEFAULT_CACHE_LOCATION}
  mkdir -p "${CACHE_LOCATION}"

  source $SWD/resources/omar_dependency_urls

  mkdir -p "${TARGET_LOCATION}"
  #touch "${TARGET_LOCATION}/${MARKER}"
  mkdir -p "${BUILD_LOCATION}"
  mkdir -p "${DEPENDENCY_BUILD_LOCATION}"
  cd "${DEPENDENCY_BUILD_LOCATION}"

  # Retrieve the dependencies
  packages=("geos" "proj4" "tiff" "geotiff" "postgresql" "postgis" "gdal" "ffmpeg" "cmake" "groovy" "grails" "tomcat" "jai" "openjpeg" "mrsid" "laszip" "kakadu" "mvapich2" "pdal" "ogg" "theora" "vorbis" "yasm" "nasm" "x264" "x265" "vpx")
  urls=("${GEOS_URL}" "${PROJ4_URL}" "${TIFF_URL}" "${GEOTIFF_URL}" "${POSTGRESQL_URL}" "${POSTGIS_URL}" "${GDAL_URL}" "${FFMPEG_URL}" "${CMAKE_URL}" "${GROOVY_URL}" "${GRAILS_URL}" "${TOMCAT_URL}" "${JAI_URL}" "${OPENJPEG_URL}" "${MRSID_URL}" "${LASZIP_URL}" "${KAKADU_URL}" "${MVAPICH2_URL}" "${PDAL_URL}" "${OGG_URL}" "${THEORA_URL}" "${VORBIS_URL}" "${YASM_URL}" "${NASM_URL}" "${X264_URL}" "${X265_URL}" "${VPX_URL}")

  git clone -b ${OPENSCENEGRAPH_BRANCH} "${OPENSCENEGRAPH_URL}"

  numpackages=${#packages[@]}
  i=0
  LAST_DEP_STEP_FILE="${BUILD_LOCATION}/.lastDepStep"
  if [ -e "${LAST_DEP_STEP_FILE}" ]; then
    # Ask for some inputs
    echo
    echo "Dependency retrieval from previous build found at ${BUILD_LOCATION}"
    echo "Do you want the dependency download to pick up where it left off? (Type y or n):"
    read -n 1 RESUME
    while [ "$RESUME" != "n" -a "$RESUME" != "y" ]; do
      unset RESUME
      read -n 1 RESUME
    done
    if [ "$RESUME" == "y" ]; then
      i=$(cat "${LAST_DEP_STEP_FILE}")
    fi
    echo
  fi
  for ((i;i<$numpackages;i++)); do
    echo $i > "${LAST_DEP_STEP_FILE}"
    retrieveDependencyWithWget "${packages[$i]}" "${urls[$i]}" 
  done

  echo $i > "${LAST_DEP_STEP_FILE}"

  # Get OSSIM
  let $((numpackages++))
  if [ $i -lt $numpackages ]; then
    getOssim
    let $((i++))
    echo $i > "${LAST_DEP_STEP_FILE}"
  fi

  if [ $RUNOPTION -eq "1" ]; then
    # Tar it all up for transfer to private network for build
    cd "${TARGET_LOCATION}"
    tar czf "omar_build_dependencies.tgz" "ossim-${OSSIM_VERSION}"
    rm -rf "ossim-${OSSIM_VERSION}"
  fi
 

fi

# Get the Tar file and extract it to the TARGET_LOCATION
if [ $RUNOPTION -eq "2" ]; then

  if [ -d "$TARGET_LOCATION" ]; then
    if [ -e "$TARGET_LOCATION" -a ! -e "${TARGET_LOCATION}/${MARKER}" -a ! -e "${TARGET_LOCATION}/omar_build_dependencies.tgz" ]; then
      echo "DESTINATION TARGET LOCATION ALREADY EXISTS AT $TARGET_LOCATION, BUT DOES NOT CONTAIN AN OMAR BUILD"
      echo "PLEASE REMOVE OR SELECT ANOTHER LOCATION"
      echo "EXITING SCRIPT"
      exit 1
    fi
  fi

  if [ ! -e "${TARGET_LOCATION}/${MARKER}" ]; then 
  DEFAULTTARFILE="${TARGET_LOCATION}/omar_build_dependencies.tgz"
  read -p "Enter tar file path to build from: (Default is $DEFAULTTARFILE): " TARFILE_LOCATION
  TARFILE_LOCATION=${TARFILE_LOCATION:-$DEFAULTTARFILE}

    if [ ! -f "${TARFILE_LOCATION}" ]; then
      echo "Selected file of ${TARFILE_LOCATION} does not exist, please supply correct path"
      echo "Exiting script"
      exit 90
    fi 
  fi

  if [ ! -e "${TARGET_LOCATION}/${MARKER}" ]; then
    mkdir -p "$TARGET_LOCATION"
    cd "$TARGET_LOCATION"
    echo 
    echo -n "Extracting TAR file ... "
    tar xzf "${TARFILE_LOCATION}" 
    echo "Status: $?"
  fi
  # If we were able to extract the tar we can skip that step if we have to rerun after a failure
fi

if [ $RUNOPTION -eq "2" -o $RUNOPTION -eq "3" ]; then
  touch "${TARGET_LOCATION}/${MARKER}"

  mkdir -p "${INSTALL_LOCATION}"
  packages=("cmake" "OpenSceneGraph" "tiff" "proj4" "geotiff" "geos" "ogg" "vorbis" "theora" "yasm" "nasm" "x264" "x265" "vpx" "ffmpeg" "gdal" "postgresql" "postgis" "openjpeg" "laszip" "kakadu" "mrsid" "mvapich2" "pdal") 
  files=($CMAKE_FILENAME $OPENSCENEGRAPH_FILENAME $TIFF_FILENAME $PROJ4_FILENAME $GEOTIFF_FILENAME $GEOS_FILENAME $OGG_FILENAME $VORBIS_FILENAME $THEORA_FILENAME $YASM_FILENAME $NASM_FILENAME $X264_FILENAME $X265_FILENAME $VPX_FILENAME $FFMPEG_FILENAME $GDAL_FILENAME $POSTGRESQL_FILENAME $POSTGIS_FILENAME $OPENJPEG_FILENAME $LASZIP_FILENAME $KAKADU_FILENAME $MRSID_FILENAME $MVAPICH2_FILENAME $PDAL_FILENAME)
  dirs=($CMAKE_DIRNAME "" $TIFF_DIRNAME $PROJ4_DIRNAME $GEOTIFF_DIRNAME $GEOS_DIRNAME $OGG_DIRNAME $VORBIS_DIRNAME $THEORA_DIRNAME $YASM_DIRNAME $NASM_DIRNAME $X264_DIRNAME $X265_DIRNAME $VPX_DIRNAME $FFMPEG_DIRNAME $GDAL_DIRNAME $POSTGRESQL_DIRNAME $POSTGIS_DIRNAME $OPENJPEG_DIRNAME $LASZIP_DIRNAME $KAKADU_DIRNAME $MRSID_DIRNAME $MVAPICH2_DIRNAME $PDAL_DIRNAME)

  numpackages=${#packages[@]}
  i=0
  LAST_BUILD_STEP_FILE="${BUILD_LOCATION}/.lastBuildStep"
  if [ -e "${LAST_BUILD_STEP_FILE}" ]; then 
    # Ask for some inputs
    echo
    echo "A partial build has been detected at ${BUILD_LOCATION}"
    echo "Do you want the build to pick up where it left off? (Type y or n):"
    read -n 1 RESUME
    while [ "$RESUME" != "n" -a "$RESUME" != "y" ]; do
      unset RESUME
      read -n 1 RESUME
    done
    if [ "$RESUME" == "y" ]; then
      i=$(cat "${LAST_BUILD_STEP_FILE}")
    fi
    echo
  fi
  for ((i;i<$numpackages;i++)); do
    echo $i > "${LAST_BUILD_STEP_FILE}"
    buildDependenciesWithMake "${packages[$i]}" "${files[$i]}" "${dirs[$i]}"
  done

  echo $i > "${LAST_BUILD_STEP_FILE}"
  
  let $((numpackages++))
  if [ $i -lt $numpackages ]; then
    echo "BUILDING OSSIM ${OSSIM_VERSION}" 
    mkdir -p "${OSSIM_BUILD_DIR}/ossim"
    cd ${OSSIM_BUILD_LOCATION}/ossim/cmake
    source $SWD/resources/ossim_cmake
    make clean
    make -j $(nproc)
    make install
    cp $SWD/resources/ossim_preferences_template "${BUILD_LOCATION}/ossim_preferences"
    export OSSIM_PREFS_FILE="${BUILD_LOCATION}/ossim_prefer
ences"
    let $((i++))
    echo $i > "${LAST_BUILD_STEP_FILE}"
  fi
fi

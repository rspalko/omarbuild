export OMAR_INSTALL=/opt/omar
export OSSIM_INSTALL_PREFIX=/opt/omar/install
export OSSIM_PREFS_FILE=$OSSIM_INSTALL_PREFIX/conf/ossim_preferences
if [ ! $JAVA_HOME ]; then
  if [ -d /usr/java/latest ]; then
    export JAVA_HOME=/usr/java/latest
    export PATH=$JAVA_HOME/bin:$PATH
  fi
fi
if [[ $JAVAVERSIONINFO =~ .*OpenJDK.* ]]; then
  if [ -d /usr/java/latest ]; then
    export JAVA_HOME=/usr/java/latest
    export PATH=$JAVA_HOME/bin:$PATH
    JAVAVERSIONINFO="$( java -version 2>&1 )"
  fi
  if [[ $JAVAVERSIONINFO =~ .*OpenJDK.* ]]; then
    echo "OMAR requires Oracle Java"
    exit 1
  fi
fi
export LD_LIBRARY_PATH=$OSSIM_INSTALL_PREFIX/lib64:$OSSIM_INSTALL_PREFIX/lib:$OSSIM_INSTALL_PREFIX/lib64/ossim/plugins
export CATALINA_HOME=$OMAR_INSTALL/tomcat
export GROOVY_HOME=$OMAR_INSTALL/groovy
export PATH=$OMAR_INSTALL/install/bin:$GROOVY_HOME/bin:$CATALINA_HOME/bin:$JAVA_HOME:$PATH


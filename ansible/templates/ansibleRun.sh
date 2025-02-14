#!/bin/bash
# This script is used to run the linux client configuration management on the client.
#
# It will check for the required software, then run ansible and finally report back
# to the service.

CONFIGURI={{ lccms.configURI }}
REPORTSURI={{ lccms.requestURI }}
ROLESURI={{ lccms.rolesURI }}
ANSIBLEDIR={{ lccms.ansibleDir }}
ANSIBLEDIRMODE={{ lccms.ansibleDirMode }}
HOST={{ lccms.host }}
UNIT={{ lccms.unit }}
LCCMSOS={{ lccms.os | default('') }}
LCCMSRELEASE={{ lccms.release | default('') }}
LCCMSCONFIGURATION={{ lccms.configuration }}   # managed, self-managed
MACHINESTATE={{ lccms.status }}  # active, retired, ...

LOGFILE=/var/log/lccmsrun.log
ACTIONDIR=/usr/local/man/ansible

out() {
  echo "$1" | /usr/bin/tee -a $LOGFILE
}
outn () {
  echo -n "$1" | /usr/bin/tee -a $LOGFILE
}


echo "===========================================" >$LOGFILE
/usr/bin/date >>$LOGFILE

OS=`/usr/bin/lsb_release -si`
RELEASE=`/usr/bin/lsb_release -sr`

out ""
out "Fetching the configuration for"
out "  host: $HOST:"
out "  unit: $UNIT"
out "  URI: $CONFIGURI"
out "  OS: $OS"
out "  release: $RELEASE"
out ""

outn "Installing required programs ... "
if ! /usr/bin/which wget >/dev/null || ! /usr/bin/which curl >/dev/null || ! /usr/bin/which sed >/dev/null
then
  out ""
  if [[ -f /usr/bin/apt ]]
  then
    /usr/bin/apt -y install wget curl sed | /usr/bin/tee -a $LOGFILE
  elif [[ -f /usr/bin/yum ]]
  then
    /usr/bin/yum -y install wget curl sed | /usr/bin/tee -a $LOGFILE
  else
    out "ERROR: Don't know how to install programs (wget, sed, curl)! Please install manually!"
    exit 1
  fi
fi
out "done."

outn "Installing ansible as package ... "
if ! /usr/bin/which ansible >/dev/null
then
  out ""
  if [[ -f /usr/bin/apt ]]
  then
    /usr/bin/apt -y install ansible | /usr/bin/tee -a $LOGFILE
  elif [[ -f /usr/bin/yum ]]
  then
    /usr/bin/yum -y install ansible | /usr/bin/tee -a $LOGFILE
  else
    out "ERROR: Don't know how to install ansible! Please install manually!"
    exit 1
  fi
fi
out "done."

outn "Checking the ansible directory ... "
[ -d $ANSIBLEDIR ] || /usr/bin/mkdir -m $ANSIBLEDIRMODE $ANSIBLEDIR
out "done."
cd $ANSIBLEDIR

outn "Updating host playbook ... "
if [[ "$OS" != "$LCCMSOS" || "$RELEASE" != "$LCCMSRELEASE" ]]
then
  # Must regenerate the playbook as the OS and/or release has changed.
  /usr/bin/mv ${ANSIBLEDIR}/${HOST}.yml ${ANSIBLEDIR}/${HOST}.yml.old
  /usr/bin/wget -q --content-disposition "${REPORTSURI}get/playbook?unit=${UNIT}&host=${HOST}&os=${OS}&release=${RELEASE}"
  if [[ $? == 0 ]]
  then
    /bin/rm -f ${ANSIBLEDIR}/${HOST}.yml.old
  else
    /usr/bin/mv ${ANSIBLEDIR}/${HOST}.yml.old ${ANSIBLEDIR}/${HOST}.yml
  fi
else
  # Can just update the playbook from the server if needed.
  /usr/bin/wget -q -N --no-parent -l 8 -nH --cut-dirs=2 -R '*.html*' --execute='robots = off' ${CONFIGURI}$UNIT/${HOST}.yml
fi
# It's ok to fail, we will just continue with the old one.
out "done."

# All directories of OS and RELEASE are lower case
LCOS=`echo $OS | /usr/bin/tr '[A-Z]' '[a-z]'`
LCRELEASE=` echo $RELEASE | /usr/bin/tr '[A-Z]' '[a-z]'`
# We have the client's playbook, extract the roles and download these.
[ -d roles ] || /usr/bin/mkdir roles
cd roles
outn "Updating roles ... "
for r in `/usr/bin/sed -n '/roles:/,$!d; / *- /s/ *- //p' ../${HOST}.yml`
do
  s=`echo $r | /usr/bin/sed 's/\./\//'`
  d=`/usr/bin/dirname $s`
  /usr/bin/wget -q -N -e robots=off --timestamping --no-parent -r -l 8 -nH --cut-dirs=3 -R '*.html*' --execute='robots = off' ${ROLESURI}${LCOS}/${LCRELEASE}/${s}/
  /usr/bin/ln -sf ${s} ${r}
done
out "done."
cd ..

out ""
out "Running ansible."
TAG=""
if [[ "$LCCMSCONFIGURATION" = "self-managed" ]] # Only execute commands with the tag 'self-managed'!
then
  echo "THIS MACHINE IS SELF MANAGED!"  >>$LOGFILE
  TAG='--tags "self-managed"'
fi
# Now run the playbook. Save the output to a file and also show on screen.
/usr/bin/ansible-playbook ${HOST}.yml $TAG | /usr/bin/tee -a $LOGFILE

if [[ "$MACHINESTATE" == "retired" ]]
then
  echo "THIS MACHINE HAS BEEN RETIRED!"  >>$LOGFILE
fi

# We will write an HTML file on what was done into $ACTIONDIR/actions.html
# Check that the path exists:
if [[ ! -d "$ACTIONDIR" ]]
then
  /usr/bin/mkdir "$ACTIONDIR"
fi
# Send the last log entry to the controller:
out "Returning log to service and updating report."
response=$(/usr/bin/curl -s -o /tmp/response.html -w '%{response_code}' --form "host=$HOST" --form "unit=$UNIT" --form "logs=@$LOGFILE" ${REPORTSURI}put/log)
if [[ $? == 0 && $response == "200" ]]
then
  /bin/mv -f /tmp/response.html ${ACTIONDIR}/actions.html
else
  /bin/rm -f /tmp/response.html
fi


#!/bin/sh

# Downloads a plugin's newest snapshot version and uploads it to the
# specified update site.
#
# It expects to find maven-helper.sh in bin/, too

die () {
	echo "$*" >&2
	exit 1
}

test $# = 4 ||
die "Usage: $0 <groupId> <artifactId> <update-site> <webdav-user>"

groupId="$1"
artifactId="$2"
update_site="$3"
webdav_user="$4"
url="http://sites.imagej.net/$update_site/"

maven_helper=bin/maven-helper.sh
version="$(sh $maven_helper latest-version $groupId:$artifactId:SNAPSHOT)"

# determine correct launcher to launch MiniMaven and the Updater
case "$(uname -s),$(uname -m)" in
Linux,x86_64) launcher=ImageJ-linux64;;
Linux,*) launcher=ImageJ-linux32;;
Darwin,*) launcher=Contents/MacOS/ImageJ-tiger;;
MING*,*) launcher=ImageJ-win32.exe;;
*) echo "Unknown platform" >&2; exit 1;;
esac

# initialize Fiji.app/ directory
curl -O http://update.imagej.net/bootstrap.js
jrunscript bootstrap.js update-force-pristine

# install plugin and dependencies using the imagej-maven-plugin
mvn -Ddelete.other.versions=true -Dimagej.app.directory=$(pwd) \
	net.imagej:imagej-maven-plugin:0.5.0:install-artifact \
	-DgroupId=$groupId -DartifactId=$artifactId -Dversion=$version

# upload complete update site
./$launcher --update remove-update-site $update_site
./$launcher --update add-update-site $update_site $url "webdav:$webdav_user:$(cat "$HOME/$webdav_user.passwd")" .
./$launcher --update upload-complete-site --force --force-shadow $update_site
./$launcher --update edit-update-site $update_site $url

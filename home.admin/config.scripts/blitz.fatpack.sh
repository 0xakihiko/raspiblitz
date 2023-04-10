#!/bin/bash
# setup script - to be called by build_sdcard.sh or on a stopped minimal build sd card image

echo -e "\n*** FATPACK ***"

echo "# getting default user/repo from build_sdcard.sh"
sudo cp /home/admin/raspiblitz/build_sdcard.sh /home/admin/build_sdcard.sh
sudo chmod +x /home/admin/build_sdcard.sh 2>/dev/null
source <(sudo /home/admin/build_sdcard.sh -EXPORT)
branch="${githubBranch}"
echo "# branch(${branch})"
echo "# defaultAPIuser(${defaultAPIuser})"
echo "# defaultAPIrepo(${defaultAPIrepo})"
echo "# defaultWEBUIuser(${defaultWEBUIuser})"
echo "# defaultWEBUIrepo(${defaultWEBUIrepo})"

# from cloned github repo
cd /home/admin/raspiblitz 2>/dev/null
repo=$(git config --get remote.origin.url | sed -n 's/.*\:\/\/github.com\/\([^\/]*\)\/.*/\1/p')
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# check if su
if [ "$EUID" -ne 0 ]
  then echo "Please run as root (with sudo)"
  exit 1
fi

echo "* Adding nodeJS Framework ..."
/home/admin/config.scripts/bonus.nodejs.sh on || exit 1

echo "* Optional Packages (may be needed for extended features)"
apt_install qrencode secure-delete fbi msmtp unclutter xterm python3-pyqt5 xfonts-terminus apache2-utils nginx python3-jinja2 socat libatlas-base-dev hexyl autossh

echo "* Adding LND ..."
/home/admin/config.scripts/lnd.install.sh install || exit 1

echo "* Adding Core Lightning ..."
/home/admin/config.scripts/cl.install.sh install || exit 1
echo "* Adding the cln-grpc plugin ..."
/home/admin/config.scripts/cl-plugin.cln-grpc.sh install || exit 1

# *** AUTO UPDATE FALLBACK NODE LIST FROM INTERNET (only in fatpack)
echo "*** FALLBACK NODE LIST ***"
# see https://github.com/rootzoll/raspiblitz/issues/1888
sudo -u admin curl -H "Accept: application/json; indent=4" https://bitnodes.io/api/v1/snapshots/latest/ -o /home/admin/fallback.bitnodes.nodes
# Fallback Nodes List from Bitcoin Core
sudo -u admin curl https://raw.githubusercontent.com/bitcoin/bitcoin/master/contrib/seeds/nodes_main.txt -o /home/admin/fallback.bitcoin.nodes

echo "* Adding Raspiblitz API ..."
sudo /home/admin/config.scripts/blitz.web.api.sh on "${defaultAPIuser}" "${defaultAPIrepo}" "blitz-${branch}" || exit 1
echo "* Adding Raspiblitz WebUI ..."
sudo /home/admin/config.scripts/blitz.web.ui.sh on "${defaultWEBUIuser}" "${defaultWEBUIrepo}" "release/${branch}" || exit 1

# set build code as new www default
sudo rm -r /home/admin/assets/nginx/www_public
sudo cp -a /home/blitzapi/blitz_web/build/* /home/admin/assets/nginx/www_public
sudo chown admin:admin /home/admin/assets/nginx/www_public
sudo rm -r /home/blitzapi/blitz_web/build/*

echo "* Adding Code&Compile for WEBUI-APP: LNBITS"
/home/admin/config.scripts/bonus.lnbits.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: JAM"
/home/admin/config.scripts/bonus.jam.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: BTCPAYSERVER"
/home/admin/config.scripts/bonus.btcpayserver.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: RTL"
/home/admin/config.scripts/bonus.rtl.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: THUNDERHUB"
/home/admin/config.scripts/bonus.thunderhub.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: BTC RPC EXPLORER"
/home/admin/config.scripts/bonus.btc-rpc-explorer.sh install || exit 1
echo "* Adding Code&Compile for WEBUI-APP: MEMPOOL"
/home/admin/config.scripts/bonus.mempool.sh install || exit 1

# set default display to LCD
sudo /home/admin/config.scripts/blitz.display.sh set-display lcd
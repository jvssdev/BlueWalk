#!/usr/bin/env bash

set -euo pipefail

echo "Installing secureblue Trivalent selinux policy"
echo "Disable Negativo repo, to prevent installing conflicting non-needed 'schily' package"
if [ -f /etc/yum.repos.d/fedora-cdrtools.repo ]; then
    dnf5 -y config-manager setopt fedora-cdrtools.enabled=0
fi
if [ -f /etc/yum.repos.d/fedora-multimedia.repo ]; then
    dnf5 -y config-manager setopt fedora-multimedia.enabled=0
fi
echo "Install 'selinux-policy-devel' build package & it's dependencies"
dnf5 -y install selinux-policy-devel
echo "Downloading secureblue Trivalent selinux policy"
TRIVALENT_POLICY_URL="https://raw.githubusercontent.com/secureblue/secureblue/refs/heads/live/files/scripts/selinux/trivalent"
SELINUX_SCRIPT_URL="https://raw.githubusercontent.com/secureblue/secureblue/refs/heads/live/files/scripts/installselinuxpolicies.sh"
curl -fLs --create-dirs -O "${TRIVALENT_POLICY_URL}/trivalent.fc" --output-dir ./selinux/trivalent
curl -fLs --create-dirs -O "${TRIVALENT_POLICY_URL}/trivalent.if" --output-dir ./selinux/trivalent
curl -fLs --create-dirs -O "${TRIVALENT_POLICY_URL}/trivalent.te" --output-dir ./selinux/trivalent
curl -fLs --create-dirs -O "${SELINUX_SCRIPT_URL}" --output-dir "${PWD}"
echo "Patching selinux script to only do Trivalent-related changes"
sed -i 's/^policy_modules=.*/policy_modules=(trivalent)/' "${PWD}/installselinuxpolicies.sh"
sed -i '/\${cil_policy_modules\[\@\]}/d' "${PWD}/installselinuxpolicies.sh"
echo "Executing trivalent.sh script"
bash "${PWD}/installselinuxpolicies.sh"
echo "Cleaning up build package 'selinux-policy-devel' & it's dependencies"
dnf5 -y remove selinux-policy-devel
echo "Enabling Negativo repos (as default state)"
if [ -f /etc/yum.repos.d/fedora-cdrtools.repo ]; then
    dnf5 -y config-manager setopt fedora-cdrtools.enabled=1
fi
if [ -f /etc/yum.repos.d/fedora-multimedia.repo ]; then
    dnf5 -y config-manager setopt fedora-multimedia.enabled=1
fi

echo "Assure that network sandbox is always disabled by default (to ensure that login data remains)"
echo "https://github.com/fedora-silverblue/issue-tracker/issues/603"
echo -e '\nCHROMIUM_FLAGS+=" --disable-features=NetworkServiceSandbox"' >> /etc/trivalent/trivalent.conf

echo "Disable search engine choice screen"
echo -e '\nCHROMIUM_FLAGS+=" --disable-search-engine-choice-screen"' >> /etc/trivalent/trivalent.conf

echo "Enable middle-click scrolling by default"
sed -i '/CHROMIUM_FLAGS+=" --enable-features=\$FEATURES"/d' /etc/trivalent/trivalent.conf
echo -e '\nFEATURES+=",MiddleClickAutoscroll"\nCHROMIUM_FLAGS+=" --enable-features=$FEATURES"' >> /etc/trivalent/trivalent.conf

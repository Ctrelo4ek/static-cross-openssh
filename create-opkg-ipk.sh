#!/bin/bash

# Описание: Упрощенный скрипт для создания .ipk пакета для статического OpenSSH.
set -e # Выходить немедленно при ошибке

# --- Настройки ---
PACKAGE_NAME="openssh"
PACKAGE_VERSION=$(curl -s "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/" | grep -oP 'openssh-\K\d+\.\d+p\d+(?=\.tar\.gz)' | sort -V | tail -n 1)
PACKAGE_ARCHITECTURE="${1:-mipsel}" # Архитектура берется из первого аргумента, по умолчанию mipsel
MAINTAINER_NAME="CrazyShoT"
MAINTAINER_EMAIL="NOMAIL"

OUTPUT_IPK_FILE="${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_ARCHITECTURE}.ipk"
TEMP_DIR="openssh_package_temp"
path="./openssh-${PACKAGE_ARCHITECTURE}/opt"

function create-cat(){
dest="$1"
cat > "$dest" <<EOF
$2
EOF
}

# --- Основная логика скрипта ---
echo "--- Сборка .ipk пакета для статического OpenSSH ---"

# Создание временных директории
mkdir -p "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}/opt" "${TEMP_DIR}/etc" "${TEMP_DIR}/opt/etc/ssh" "${TEMP_DIR}/opt/sbin" "${TEMP_DIR}/opt/libexec"

# Создание файла control
create-cat "${TEMP_DIR}/control" "Package: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Alternatives: 200:/opt/bin/ssh:/opt/libexec/ssh, 200:/opt/bin/scp:/opt/libexec/scp, 200:/opt/bin/sftp:/opt/libexec/sftp, 200:/opt/bin/sftp-server:/opt/libexec/sftp-server
Source: feeds/packages/net/openssh
SourceName: openssh
License: BSD ISC
LicenseFiles: LICENCE
Section: net
SourceDateEpoch: 1736511695
URL: https://www.openssh.com/
CPE-ID: cpe:/a:openssh:openssh
Maintainer: NoName <NOMAIL>
Architecture: mipsel-3.4
Installed-Size: 1300480
Description:  OpenSSH full."

# Создание файла conffiles
create-cat "${TEMP_DIR}/conffiles" "/opt/etc/ssh/ssh_config"

# Создание файла postinst
create-cat "${TEMP_DIR}/postinst" '#!/bin/sh
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s ${IPKG_INSTROOT}/lib/functions.sh ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
default_postinst $0 $@'

# Создание файла prerm
create-cat "${TEMP_DIR}/prerm" "#!/bin/sh
[ -s ${IPKG_INSTROOT}/lib/functions.sh ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
default_prerm $0 $@"

# Создание файла debian-binary
create-cat "${TEMP_DIR}/debian-binary" "2.0"

#tree
# 5. Копирование бинарников и конфигурационных файлов
cp -v ${path}/bin/* ${TEMP_DIR}/opt/libexec/
cp -v ${path}/libexec/* ${TEMP_DIR}/opt/libexec/
cp -v ${path}/sbin/* ${TEMP_DIR}/opt/sbin/
cp -v ${path}/etc/ssh/* ${TEMP_DIR}/opt/etc/ssh/
#cp -v "${SSH_BINARY_PATH}" "${TEMP_DIR}/opt/libexec/ssh-openssh"
#cp -v "${SSHD_BINARY_PATH}" "${TEMP_DIR}/opt/sbin/sshd"
#if [ -n "${SSH_CONFIG_PATH}" ]; then cp -v "${SSH_CONFIG_PATH}" "${TEMP_DIR}/opt/etc/ssh/ssh_config"; fi
#if [ -n "${SSHD_CONFIG_PATH}" ]; then cp -v "${SSHD_CONFIG_PATH}" "${TEMP_DIR}/opt/etc/ssh/sshd_config"; fi

# 6. Создание архивов и debian-binary
pushd "${TEMP_DIR}" #> /dev/null
  tar -czf control.tar.gz ./control ./conffiles ./postinst ./prerm
  #tar -czf control.tar.gz ./control ./conffiles
  tar -czf data.tar.gz ./opt
  tar -czf "../${OUTPUT_IPK_FILE}" ./debian-binary ./control.tar.gz ./data.tar.gz
popd #> /dev/null

# 7. Удаление временной директории
rm -rf "${TEMP_DIR}"
pwd
echo "--- .ipk пакет успешно создан в $(pwd): ${OUTPUT_IPK_FILE} ---"
echo "Теперь вы можете установить этот пакет на ваше Entware устройство с помощью:"
echo "opkg install ${OUTPUT_IPK_FILE}"

exit 0


create_control_file() {
mkdir -p "${TEMP_DIR}/control"
cat > "${TEMP_DIR}/control/control" <<EOF
Package: ${PACKAGE_NAME}-client-static
Version: ${PACKAGE_VERSION}
Architecture: ${PACKAGE_ARCHITECTURE}
Maintainer: ${MAINTAINER_NAME} <${MAINTAINER_EMAIL}>
Section: net
Priority: optional
Essential: no
Description: Static OpenSSH ${PACKAGE_VERSION} client for Entware (no dependencies)
 Provides: ssh-client-static # Изменим Provides, чтобы отразить статический билд
 Conflicts: openssh, openssh-server, openssh-client, openssh-client-static # Добавим конфликт с самим собой
 Replaces: openssh, openssh-server, openssh-client, openssh-client-static # Добавим replaces для старой версии статического билда
Alternatives: 200:/opt/bin/ssh:/opt/libexec/ssh-openssh, 200:/opt/bin/scp:/opt/libexec/scp-openssh # Альтернативы (оставляем, как есть, если нужно)
Source: feeds/packages/net/openssh # Источник (можно оставить, или убрать, если это не из фидов)
SourceName: openssh # Имя источника (аналогично)
License: BSD ISC # Лицензия (как есть)
LicenseFiles: LICENCE # Файлы лицензии (как есть)
SourceDateEpoch: 1736511695 # Source Date Epoch (как есть)
URL: https://www.openssh.com/ # URL (как есть)
CPE-ID: cpe:/a:openssh:openssh # CPE ID (как есть)
Installed-Size: 1300480 # Установленный размер (примерное значение, нужно будет уточнить для статического билда)
EOF
}
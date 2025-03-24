#!/bin/bash

# Название скрипта: build_openssh_ipk_v2.sh
# Описание: Упрощенный скрипт для создания .ipk пакета для статического OpenSSH.

set -e # Выходить немедленно при ошибке

# --- Настройки ---
PACKAGE_NAME="openssh"
PACKAGE_VERSION="9.9p2"  # Измените на вашу версию
PACKAGE_ARCHITECTURE="${1:-mipsel}" # Архитектура берется из первого аргумента, по умолчанию mipsel
MAINTAINER_NAME="CrazyShoT"
MAINTAINER_EMAIL="NOMAIL"

OUTPUT_IPK_FILE="${PACKAGE_NAME}-${PACKAGE_VERSION}-${PACKAGE_ARCHITECTURE}.ipk"
TEMP_DIR="openssh_package_temp"

function create-cat(){
dest="$1"
cat > "$dest" <<EOF
$2
EOF
}

# --- Основная логика скрипта ---

echo "--- Сборка .ipk пакета для статического OpenSSH ---"

# 1. Запрос необходимой информации от пользователя
#read -ep "Введите архитектуру целевой системы (например, mipsel, armv7l, x86_64) [${PACKAGE_ARCHITECTURE}]: " input_arch
#PACKAGE_ARCHITECTURE="${input_arch:-${PACKAGE_ARCHITECTURE}}" # Используем ввод пользователя или значение по умолчанию

#read -ep "Введите путь к бинарнику ssh: " SSH_BINARY_PATH
#read -ep "Введите путь к бинарнику sshd: " SSHD_BINARY_PATH
#read -ep "Введите путь к файлу ssh_config (оставьте пустым, если не нужен): " SSH_CONFIG_PATH
#read -ep "Введите путь к файлу sshd_config (оставьте пустым, если не нужен): " SSHD_CONFIG_PATH
#path="./output/${PACKAGE_ARCHITECTURE}/openssh-${PACKAGE_ARCHITECTURE}/opt"
path="./openssh-${PACKAGE_ARCHITECTURE}/opt"

#SSH_BINARY_PATH="${path}/bin/ssh"
#SCP_BINARY_PATH="${path}/scp"
#SSHD_BINARY_PATH="/xbin/sshd"
#SSH_CONFIG_PATH="/etc/ssh/ssh_config"
#SSHD_CONFIG_PATH="/etc/ssh/sshd_config"
#MODULI_CONFIG_PATH="/etc/ssh/moduli"

# 2. Проверка существования файлов бинарников
#if [ ! -f "${SSH_BINARY_PATH}" ]; then echo "Ошибка: Файл не найден: ${SSH_BINARY_PATH}"; exit 1; fi
#if [ ! -f "${SSHD_BINARY_PATH}" ]; then echo "Ошибка: Файл не найден: ${SSHD_BINARY_PATH}"; exit 1; fi
#if [ -n "${SSH_CONFIG_PATH}" ] && [ ! -f "${SSH_CONFIG_PATH}" ]; then echo "Ошибка: Файл не найден: ${SSH_CONFIG_PATH}"; exit 1; fi
#if [ -n "${SSHD_CONFIG_PATH}" ] && [ ! -f "${SSHD_CONFIG_PATH}" ]; then echo "Ошибка: Файл не найден: ${SSHD_CONFIG_PATH}"; exit 1; fi

# 3. Создание временных директории
mkdir -p "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}/opt" "${TEMP_DIR}/etc" "${TEMP_DIR}/opt/etc/ssh" "${TEMP_DIR}/opt/sbin" "${TEMP_DIR}/opt/libexec"

# 4. Создание файла control
create-cat "${TEMP_DIR}/control" "Package: ${PACKAGE_NAME}-client-static
Version: ${PACKAGE_VERSION}
Depends:
Alternatives: 200:/opt/bin/ssh:/opt/libexec/ssh-openssh, 200:/opt/bin/scp:/opt/libexec/scp-openssh
Source: feeds/packages/net/openssh
SourceName: openssh
License: BSD ISC
LicenseFiles: LICENCE
Section: net
SourceDateEpoch: 1736511695
URL: https://www.openssh.com/
CPE-ID: cpe:/a:openssh:openssh
Maintainer: NoName <NOMAIL>
Architecture: mipsel
Installed-Size: 1300480
Description:  OpenSSH client"

create-cat "${TEMP_DIR}/conffiles" "/opt/etc/ssh/ssh_config"
create-cat "${TEMP_DIR}/postinst" '#!/bin/sh
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s ${IPKG_INSTROOT}/lib/functions.sh ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
default_postinst $0 $@'
create-cat "${TEMP_DIR}/prerm" "#!/bin/sh
[ -s ${IPKG_INSTROOT}/lib/functions.sh ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
default_prerm $0 $@"
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
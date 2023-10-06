openssl/DEFAULT_VERSION := 1.1.1v
define openssl/determine_latest
  $(eval override openssl/VERSION := $(shell
    . ./version.sh;
	list_github_tags https://github.com/openssl/openssl |
	sed -En '/^OpenSSL_1/{s/^OpenSSL_(.*)$$/\1/; y/_/./; p}' |
	sort_versions | tail -n 1
  ))
endef
$(call determine_version,openssl,$(openssl/DEFAULT_VERSION))

openssl/TARBALL := https://www.openssl.org/source/openssl-$(openssl/VERSION).tar.gz

openssl/dir = $(build_dir)/openssl/openssl-$(openssl/VERSION)

define openssl/build :=
	+cd '$(openssl/dir)'
	./Configure --prefix="$(prefix)" --cross-compile-prefix="$(host_triplet)-" \
		no-shared no-asm linux-elf
	'$(MAKE)'
endef

define openssl/install :=
	+'$(MAKE)' -C '$(openssl/dir)' install DESTDIR='$(staging_dir)'
endef

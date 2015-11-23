# == Define: uhosting::helper::python_pip
#
# Installs PIP packages
#
# === Authors
#
# Tobias Brunner <tobias.brunner@vshn.ch>
#
# === Copyright
#
# Copyright 2015 Tobias Brunner, VSHN AG
#
define uhosting::helper::python_pip (
  $ensure,
  $virtualenv,
  $orig_name,
  $pip_packages,
) {

  $pkgname = delete($name,"${orig_name}-")

  python::pip { $name:
    ensure         => $ensure,
    pkgname        => $pkgname,
    virtualenv     => $virtualenv,
    owner          => $orig_name,
    log_dir        => $pip_packages[$pkgname]['log_dir'],
    url            => $pip_packages[$pkgname]['url'],
    install_args   => $pip_packages[$pkgname]['install_args'],
    uninstall_args => $pip_packages[$pkgname]['uninstall_args'],
  }

}


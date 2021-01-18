# == Define cobbler::config::ini
#
# Helps build ini configuration files for cobbler
#
# === Parameters
#
# [*config_file*]
#   Absolute path to configuration file
#
#   Type: String
#   Default: nil
#
# [*options*]
#   Hash of options to build config_file upon.
#
#   Exapmple:
#     cobbler_modules_config => {
#       section1            => {
#         option1 => value1,
#         option2 => [ value1, value2],
#       },
#       section2.subsection => {
#         option3 => value3,
#       }
#     }
#
#   Type: Hash
#   Default: {}
#
# === Authors
#
# Anton Baranov <abaranov@linuxfoundation.org>
define cobbler::config::ini (
  Enum['present','absent'] $ensure,
  Stdlib::Compat::Absolute_Path $config_file,
  Stdlib::Compat::Hash $options
) {

  File {
    mode  => '0644',
    owner => 'root',
    group => 'root',
  }

  file { $config_file:
    ensure  => $ensure,
    content => template("${module_name}/ini.erb")
  }
}

# arincli -- ARIN Command Line Interface

## DESCRIPTION

ARINcli is a set of command line scripts, written in Ruby, that utilize both
the Whois-RWS service and the 
Reg-RWS service. Whois-RWS is ARIN's Whois/NICNAME RESTful web service for
exposing IP network and ASN registration data to the public (Note this service
pre-dates the IETF WEIRDS/RDAP service and is not yet compatible with that
specification). Reg-RWS is ARIN's
registration RESTful web service available to customers of ARIN.

At the time of this writing, the ARINcli scripts should be considered **beta**
quality. A lot of functionality is still missing from the scripts, and ARIN 
has not conducted any degree of quality assurance against them.

## COMMANDS

  * `arininfo` queries ARIN's Whois-RWS service.

  * `poc` creates, modifies, and deletes Point of Contacts (POCs).

  * `rdns` modifies reverse DNS delegations.

  * `ticket` downloads, displays and manages Reg-RWS tickets.

  * `arinreports` requests reports from ARIN using Reg-RWS.

  * `arinutil` is a utility for managing ARINcli scripts.

## CONFIGURATION

The ARINcli commands all use an application data directory to store configuration
files, caches, etc. The arinutil(1) command can be used to manipulate the caches
and configuration. This application data directory is `$HOME/.ARINcli` for Unix
and Unix-like systems, and `%APPDATA%\ARINcli` for Windows. This directory is
created automatically the first time an ARINcli command is run.

Configuration is kept in the `config.yaml` file in the application data directory.
This is a YAML file and so YAML syntax is required. YAML is designed to be human
friendly yet machine parsable. For users of Reg-RWS, the API Key given will
likely need be changed to the users real API key. An API Key can be obtained
via [ARIN Online](http://www.arin.net/public). An API Key is not needed for
Whois-RWS.

## INSTALLATION

At present, there are two ways to install this code: 1) via a Git clone from [GitHub](https://github.com/arineng/arincli.git), or 2) from a zip file release on [GitHub](https://github.com/arineng/arincli/releases).

The ARINcli commands are Ruby programs, and Ruby 1.8.7 and above
are needed.

To verify compatibility and that everything is working, run the tests with
the `run_all_tests` command.

To build the man pages and these documents, you must use `ronn`. You can
install it as a Ruby gem with _gem install ronn_. Once it is installed,
build the man pages with the following command: _ronn man/*.ronn_.

## HELP

Questions and comments regarding this software may be directed to ARIN's
Technical Discussion mailing list (arin-tech-discuss@arin.net). Archives
and subscription information are available at
[http://lists.arin.net/pipermail/arin-tech-discuss/](http://lists.arin.net/pipermail/arin-tech-discuss/).


# Copyright (C) 2011 American Registry for Internet Numbers
#
# IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
#   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx

module ARINr

  VERSION = "ARINr v.0.1.0"
  COPYRIGHT = "Copyright (c) 2011 American Registry for Internet Numbers (ARIN)"

  # regular expressions
  NET_HANDLE_REGEX = /^NET-.*/i
  NET6_HANDLE_REGEX = /^NET6-.*/i
  POC_HANDLE_REGEX = /.*-ARIN$/i
  ORGL_HANDLE_REGEX = /.*-Z$/i
  ORGS_HANDLE_REGEX = /.*-O$/i

  # IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
  #   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx
  IPV4_REGEX = /\A(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}\z/
  IPV6_REGEX = /\A(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z/
  IPV6_HEXCOMPRESS_REGEX = /\A((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)\z/

end

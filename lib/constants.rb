# Copyright (C) 2011,2012 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

#
# IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
#   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx

module ARINr

  VERSION = "ARINr v.0.1.0"
  COPYRIGHT = "Copyright (c) 2011,2012 American Registry for Internet Numbers (ARIN)"

  # regular expressions
  NET_HANDLE_REGEX = /^NET-.*/i
  NET6_HANDLE_REGEX = /^NET6-.*/i
  POC_HANDLE_REGEX = /.*-ARIN$/i
  ORGL_HANDLE_REGEX = /.*-Z$/i
  ORGS_HANDLE_REGEX = /.*-O$/i
  ORGN_HANDLE_REGEX = /\w+\-\d+/
  AS_REGEX = /^[0-9]{1,10}$/
  ASN_REGEX = /^AS[0-9]{1,20}$/i
  IP4_ARPA = /\.in-addr\.arpa[\.]?/i
  IP6_ARPA = /\.ip6\.arpa[\.]?/i
  DATA_TREE_ADDR_REGEX = /\d=$/

  # IPv4 and IPv6 regular expressions are credited to Mike Poulson and are found here:
  #   http://blogs.msdn.com/b/mpoulson/archive/2005/01/10/350037.aspx
  IPV4_REGEX = /\A(25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3}\z/
  IPV6_REGEX = /\A(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\z/
  IPV6_HEXCOMPRESS_REGEX = /\A((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::((?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)\z/

  #File Name Constants
  ARININFO_LASTTREE_YAML = "arininfo-lasttree.yaml"
  TICKET_TREE_YAML       = "ticket-tree.yaml"

end

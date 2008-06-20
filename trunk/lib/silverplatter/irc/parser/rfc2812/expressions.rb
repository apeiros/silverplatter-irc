#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

# This file is instance_eval'ed on a SilverPlatter::IRC::Parser, so see there for
# available methods

add_expression :who_flags,  /[#{Regexp.escape(@isupport.prefixes)}]{0,#{@isupport.prefixes.size}}/
add_expression :delete_who_flags, /\A#{expression.who_flags}/



# These expressions implement RFC2812, Section 2.3.1

add_expression :special,    /[\[\]\\`_^{|}]/
add_expression :letter,     /[A-Za-z]/
add_expression :hex,        /[\dA-Fa-f]/
add_expression :channel_id, /[A-Z\d]{5}/
add_expression :chanstring, /[^\x00\x07\x10\x0D\x20,:]/
add_expression :channel,    /(?:[#+&]|!#{expression.channel_id})#{expression.chanstring}(?::#{expression.chanstring})?/
add_expression :user,       /[^\x00\x10\x0D\x20@]+/
add_expression :nick,       /[A-Za-z\[\]\\`_^{|}][A-Za-z\d\[\]\\`_^{|}-]{0,7}/
add_expression :command,    /[A-Za-z]+|\d{3}/
add_expression :ip4addr,    /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
add_expression :ip6addr,    /[\dA-Fa-f](?::[\dA-Fa-f]){7}|0:0:0:0:0:(?:0|[Ff]{4}):#{expression.ip4addr}/
add_expression :hostaddr,   /#{expression.ip4addr}|#{expression.ip6addr}/
add_expression :shortname,  /[A-Za-z0-9][A-Za-z0-9-]*/
add_expression :hostname,   /#{expression.shortname}(?:\.#{expression.shortname})*/
add_expression :host,       /#{expression.hostname}|#{expression.hostaddr}/
add_expression :prefix,     /
  # HOSTNAME
  (#{expression.hostname})|
  # HOSTMASK
    # NICK
    (#{expression.nick})
    # USER
    (?:(?:!(#{expression.user}))?
    # HOST
    @(#{expression.host}))?
/x
add_expression :middle,     /[^\x00\x20\r\n:][^\x00\x20\r\n]*/
add_expression :trailing,   /[^\x00\r\n]*/
add_expression :params,     /((?:\x20#{expression.middle}){0,14}(?:\x20:?#{expression.trailing})?)/
add_expression :message,    /^
# PREFIX
(:#{expression.prefix}\x20)?
# COMMAND
(#{expression.command})
# PARAMS
(?:#{expression.params})?
$/x

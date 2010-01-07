#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

# This file is instance_eval'ed on a SilverPlatter::IRC::Parser, so see there for
# available methods



# These expressions implement RFC2812, Section 2.3.1

add_expression :special,    /[\[\]\\`_^{|}]/
add_expression :letter,     /[A-Za-z]/
add_expression :hex,        /[\dA-Fa-f]/
add_expression :channel_id, /[A-Z\d]{5}/
add_expression :chanstring, /[^\x00\x07\x10\x0D\x20,:]/
add_expression :channel,    /(?:[#+&]|!#{new_expression.channel_id})#{new_expression.chanstring}(?::#{new_expression.chanstring})?/
add_expression :user,       /[^\x00\x10\x0D\x20@]+/
add_expression :nick,       /[A-Za-z\[\]\\`_^{|}][A-Za-z\d\[\]\\`_^{|}-]{0,7}/
add_expression :command,    /[A-Za-z]+|\d{3}/
add_expression :ip4addr,    /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
add_expression :ip6addr,    /[\dA-Fa-f](?::[\dA-Fa-f]){7}|0:0:0:0:0:(?:0|[Ff]{4}):#{new_expression.ip4addr}/
add_expression :hostaddr,   /#{new_expression.ip4addr}|#{new_expression.ip6addr}/
add_expression :shortname,  /[A-Za-z0-9][A-Za-z0-9-]*/
add_expression :hostname,   /#{new_expression.shortname}(?:\.#{new_expression.shortname})*/
add_expression :host,       /#{new_expression.hostname}|#{new_expression.hostaddr}/
add_expression :prefix,     /
  # HOSTNAME
  (#{new_expression.hostname})|
  # HOSTMASK
    # NICK
    (#{new_expression.nick})
    # USER
    (?:(?:!(#{new_expression.user}))?
    # HOST
    @(#{new_expression.host}))?
/x
add_expression :middle,     /[^\x00\x20\r\n:][^\x00\x20\r\n]*/
add_expression :trailing,   /[^\x00\r\n]*/
add_expression :params,     /((?:\x20#{new_expression.middle}){0,14}(?:\x20:?#{new_expression.trailing})?)/
add_expression :message,    /^
# PREFIX
(:#{new_expression.prefix}\x20)?
# COMMAND
(#{new_expression.command})
# PARAMS
(?:#{new_expression.params})?
$/x

#! /usr/bin/env python
# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright 2012 AT&T
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import argparse
import subprocess

import netaddr

DESCRIPTION = "A `nova-manage floating create` wrapper."


class FloatingAddress(object):
    """
    A simple wrapper class for creating networks.  Often
    times there are reserved addresses at the start of a
    network, nova-manage doesn't account for this.

    TODO(retr0h): This should really be added to nova-manage.
    """

    def _add_cidr(self, cidr):
        """
        Validates the provided cider address, and passes it to nova-manage.

        :param cidr: A string containing a valid CIDR address.
        """
        try:
            netaddr.IPNetwork(cidr)
            self._add_floating(cidr)
        except netaddr.core.AddrFormatError:
            raise

    def _add_range(self, start, end):
        """
        Takes a start and end range, and creates individual host addresses.

        :param start: A string containing the start of the range.
        :param end: A string containing the end of the range.
        """
        ip_list = list(netaddr.iter_iprange(start, end))
        for ip in ip_list:
            ip = '{0}/32'.format(ip)
            self._add_floating(ip)

    def _add_floating(self, ip):
        cmd = "nova-manage floating create --ip_range={0}".format(ip)

        subprocess.check_call(cmd, shell=True)

def _parse_args():
    ap = argparse.ArgumentParser(description=DESCRIPTION)
    ap.add_argument('-d', '--dry_run', action='store_true',
                    default=False, help='Show dry run output')
    group = ap.add_mutually_exclusive_group()
    group.add_argument('--cidr',
                       help="A CIDR notation of addresses to add "
                            "(e.g. 192.168.0.0/24)")
    group.add_argument('--ip-range',
                       help="A range of addresses to add "
                            "(e.g. 192.168.0.10,192.168.0.50)")
    return ap.parse_args()

if __name__ == '__main__':
    args = _parse_args()
    fa = FloatingAddress()

    if args.cidr:
        fa._add_cidr(args.cidr)
    elif args.ip_range:
        start, end = args.ip_range.split(',')
        fa._add_range(start, end)

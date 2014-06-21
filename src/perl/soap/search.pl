#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2013 Zimbra, Inc.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 

use strict;
use lib '.';

use LWP::UserAgent;
use Getopt::Long;
use XmlDoc;
use Soap;
use ZimbraSoapTest;

# specific to this app
my ($searchString, $offset, $prevId, $prevSortVal, $endSortVal, $limit, $fetch, $sortBy, $types, $convId, $tz, $locale, $field);
my ($calExpandInstStart, $calExpandInstEnd, $allowableTaskStatus);
$offset = 0;
$limit = 5;
$fetch = 0;
$sortBy = "dateDesc";
$types = "message";

#standard options
my ($admin, $user, $pw, $host, $help, $adminHost); #standard
GetOptions("u|user=s" => \$user,
           "admin" => \$admin,
           "ah|adminHost=s" => \$adminHost,
           "pw=s" => \$pw,
           "h|host=s" => \$host,
           "help|?" => \$help,
           # add specific params below:
           "t|types=s" => \$types,
           "conv=s" => \$convId,
           "query=s" => \$searchString,
           "sort=s" => \$sortBy,
           "offset=i" => \$offset,
           "limit=i" => \$limit,
           "fetch=s" => \$fetch,
           "pi=s" => \$prevId,
           "ps=s" => \$prevSortVal,
           "es=s" => \$endSortVal,
           "tz=s" => \$tz,
           "locale=s" => \$locale,
           "field=s" => \$field,
           "calExpandInstStart=s" => \$calExpandInstStart,
           "calExpandInstEnd=s" => \$calExpandInstEnd,
           "allowableTaskStatus=s" => \$allowableTaskStatus,
          );



if (!defined($user) || !defined($searchString) || defined($help)) {
    my $usage = <<END_OF_USAGE;
    
USAGE: $0 -u USER -q QUERYSTR [-s SORT] [-t TYPES] [-o OFFSET] [-l LIMIT] [-fetch FETCH] [-pi PREV-ITEM-ID -ps PREV-SORT-VALUE] [-es END-SORT-VALUE] [-conv CONVID] [-tz TZID] [-calExpandInstStart STARTTIME -calExpandInstEnd ENDTIME] [-locale LOCALE_STR] [-allowableTaskStatus=INPR,NEED,DEFERRED,WAITING,COMP]
    SORT = dateDesc|dateAsc|subjDesc|subjAsc|nameDesc|nameAsc|score|none
    TYPES = message|conversation|contact|appointment
END_OF_USAGE
    die $usage;
}

if (defined($adminHost)) {
  $admin = 1;
}

my $z = ZimbraSoapTest->new($user, $host, $pw, undef, $adminHost);
if (defined($admin)) {
  $z->doAdminAuth();
} else {
  $z->doStdAuth();
}

my $d = new XmlDoc;
my $searchName = "SearchRequest";

my %args =  ( 'types' => $types,
              'sortBy' => $sortBy,
              'offset' => $offset,
              'limit' => $limit,
              'fetch' => $fetch
            );

if (defined($calExpandInstStart)) {
  $args{'calExpandInstStart'} = $calExpandInstStart;
  $args{'calExpandInstEnd'} = $calExpandInstEnd;
}

if (defined($allowableTaskStatus)) {
  $args{'allowableTaskStatus'} = $allowableTaskStatus;
}

if (defined($convId)) {
  $searchName = "SearchConvRequest";
  $args{'cid'} = $convId;
}

if (defined($field)) {
  $args{'field'} = $field;
}
 
$d->start($searchName, $Soap::ZIMBRA_MAIL_NS, \%args);
{
    if (defined $prevId) {
      if (defined $endSortVal) {
        $d->add("cursor", undef, { "id" => $prevId, "sortVal" => $prevSortVal, "endSortVal" => $endSortVal });
      } else {
        $d->add("cursor", undef, { "id" => $prevId, "sortVal" => $prevSortVal });
      }
    }

    $d->add('query', undef, undef, $searchString);

    if (defined $tz) {
      $d->add('tz', undef, {"id" => $tz });
    }

    if (defined $locale) {
      $d->add('locale', undef, undef, $locale);
    }
    
} $d->end(); # 'SearchRequest'

my $response = $z->invokeMail($d->root());

print "REQUEST:\n-------------\n".$z->to_string_simple($d);
print "RESPONSE:\n--------------\n".$z->to_string_simple($response);


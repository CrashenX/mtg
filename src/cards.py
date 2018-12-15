# Copyright 2018 Jesse J. Cook
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# cards.py

import argparse
from pymongo import MongoClient
from requests import get as httpget

actions = ['load', 'dump', 'drop']
targets = ['carddata', 'mycollection']
all_targets = 'everything'


def load_cards(table):
    print("Loading Card Data...")
    r = httpget('https://mtgjson.com/v4/json/AllCards.json')
    if r.status_code != 200:
        print("Loading card data from mtgjson.com failed with status: %d" %
              r.status_code)
        exit(1)
    for k, v in r.json().items():
        table.insert_one(v).inserted_id


def load(args, db):
    print("Load function executed %s" % args.target)
    if args.target == 'carddata':
        load_cards(db.carddata)


def dump(args, db):
    print("Dump function executed %s" % args.target)


def drop(args, db):
    print("Drop function executed with %s" % args.target)
    if args.target == all_targets:
        for t in targets:
            getattr(db, t).drop()
    else:
        getattr(db, args.target).drop()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Manage MTG Collection')
    subparsers = parser.add_subparsers(metavar='CMD')
    for cmd in actions:
        p = subparsers.add_parser(cmd, help='%s mtg data' % cmd)
        tgts = targets + [all_targets]
        p.add_argument('target',
                       metavar='DATA',
                       type=str,
                       choices=tgts,
                       help="{%s}" % '|'.join(tgts))
        p.set_defaults(func=locals()[cmd])
    subparsers.required = True
    args = parser.parse_args()
    client = MongoClient()
    db = client.mtg
    args.func(args, db)

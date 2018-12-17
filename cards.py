#!venv/bin/python
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

from argcomplete import autocomplete
from argparse import ArgumentParser, ArgumentTypeError
from pymongo import MongoClient
from bson.json_util import loads, dumps
from requests import get as httpget
from requests import codes
from sys import stdout

ACTIONS = ['get', 'load', 'dump', 'drop']
TARGETS = ['cards', 'sets', 'collection']
ALL_TARGETS = 'everything'
BACKUPS = 'backups/'


def get(db, target):
    def target_get(db, target):
        for i in getattr(db, target).find({}, {'_id': 0}).limit(args.limit):
            print(i)

    if args.target == ALL_TARGETS:
        for t in TARGETS:
            target_get(db, t)
    else:
        target_get(db, args.target)


def load_backup(db, target):
    print("Loading %s from %s directory..." % (target, BACKUPS), end='')
    stdout.flush()
    with open("%s/%s.json" % (BACKUPS, target), 'r') as f:
        for i in loads(f.read()):
            getattr(db, target).insert_one(i).inserted_id
    print("Done")


def load_mtgjson(db, target):
    print("Loading %s from mtgjson.com..." % target, end='')
    stdout.flush()
    emsg = ""
    try:
        r = httpget('https://mtgjson.com/v4/json/All%s.json' %
                    target.capitalize())
    except Exception as e:
        emsg = str(e)
    if emsg == "" and r.status_code != codes.ok:
        emsg = "Received status code: %d" % r.status_code
    if emsg == "":
        for k, v in r.json().items():
            getattr(db, target).insert_one(v).inserted_id
        print("Done")
    else:
        print("Error❗- Loading data from mtgjson.com failed: %s" % emsg)
        print("🛈 The system will attempt to load from backup instead.")
        load_backup(db, target)


def load(db, args):
    def target_load(db, target):
        def load_cards(db, target):
            load_mtgjson(db, target)

        def load_sets(db, target):
            load_mtgjson(db, target)

        def load_collection(db, target):
            load_backup(db, target)

        locals()["load_%s" % target](db, target)

    drop(db, args)
    if args.target == ALL_TARGETS:
        for t in TARGETS:
            target_load(db, t)
    else:
        target_load(db, args.target)


def dump(db, args):
    def target_dump(db, target):
        print("Dumping %s..." % target, end='')
        stdout.flush()
        with open("%s/%s.json" % (BACKUPS, target), 'w') as f:
            f.write(dumps(getattr(db, target).find({}, {"_id": 0})))
        print("Done")

    if args.target == ALL_TARGETS:
        for t in TARGETS:
            target_dump(db, t)
    else:
        target_dump(db, args.target)


def drop(db, args):
    def target_drop(db, target):
        print("Dropping %s..." % target, end='')
        stdout.flush()
        getattr(db, target).drop()
        print("Done")

    if args.target == ALL_TARGETS:
        for t in TARGETS:
            target_drop(db, t)
    else:
        target_drop(db, args.target)


def check_positive(v):
    i = int(v)
    if i <= 0:
        raise ArgumentTypeError("%s is not a positive integer" % v)
    return i


if __name__ == '__main__':
    parser = ArgumentParser(description='Manage MTG Collection')
    subparsers = parser.add_subparsers(metavar='CMD')
    for cmd in ACTIONS:
        p = subparsers.add_parser(cmd, help='%s mtg data' % cmd)
        tgts = TARGETS + [ALL_TARGETS]
        p.add_argument('target',
                       metavar='DATA',
                       type=str,
                       choices=tgts,
                       help="{%s}" % '|'.join(tgts))
        p.set_defaults(func=locals()[cmd])
        if cmd == 'get':
            p.add_argument("--limit", default=10, type=check_positive,
                           help="max records returned (positive integer)")
    subparsers.required = True
    autocomplete(parser)
    args = parser.parse_args()
    client = MongoClient()
    db = client.mtg
    args.func(db, args)

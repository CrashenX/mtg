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
import os
import sys

actions = ['load', 'dump', 'drop']
targets = ['cards', 'sets', 'collection']
all_targets = 'everything'


def load_mtgjson(db, target):
    r = httpget('https://mtgjson.com/v4/json/All%s.json' %
                target.capitalize())
    if r.status_code != 200:
        print("Error\n\tLoading %s from mtgjson.com failed with status: %d" %
              (target, r.status_code))
        exit(1)
    for k, v in r.json().items():
        getattr(db, target).insert_one(v).inserted_id


def load(db, args):
    def target_load(db, target):
        def load_cards(db, target):
            load_mtgjson(db, target)

        def load_sets(db, target):
            load_mtgjson(db, target)

        def load_collection(db, target):
            pass

        print("Loading %s..." % target, end='')
        sys.stdout.flush()
        locals()["load_%s" % target](db, target)
        print("Done")

    if args.target == all_targets:
        for t in targets:
            target_load(db, t)
    else:
        target_load(db, args.target)


def dump(db, ags):
    def target_dump(db, target):
        print("Dumping %s..." % target, end='')
        sys.stdout.flush()
        with open("%s.json" % target, 'w') as f:
            f.write('[\n')
            for i in getattr(db, target).find({}, {"_id": 0}):
                f.write("    %s,\n" % i)
            f.seek(f.tell() - 2, os.SEEK_SET)
            f.write('\n]')
        print("Done")

    if args.target == all_targets:
        for t in targets:
            target_dump(db, t)
    else:
        target_dump(db, args.target)


def drop(db, args):
    def target_drop(db, target):
        print("Dropping %s..." % target, end='')
        sys.stdout.flush()
        getattr(db, target).drop()
        print("Done")

    if args.target == all_targets:
        for t in targets:
            target_drop(db, t)
    else:
        target_drop(db, args.target)


# def load_cards(db, args):
#     # load_mtgjson(db, args.target)
#     print("Load cards: %s %s" % (args.action, args.target))
#
#
# def load_sets(db, args):
#     # load_mtgjson(db, args.target)
#     print("Load sets: %s %s" % (args.action, args.target))
#
#
# def load_collection(db, args):
#     print("Load collection: %s %s" % (args.action, args.target))
#
#
# def dump_cards(db, args):
#     print("Dump cards: %s %s" % (args.action, args.target))
#
#
# def dump_sets(db, args):
#     print("Dump sets: %s %s" % (args.action, args.target))
#
#
# def dump_collection(db, args):
#     print("Dump collection: %s %s" % (args.action, args.target))
#
#
# def drop_cards(db, args):
#     print("Drop cards: %s %s" % (args.action, args.target))
#
#
# def drop_sets(db, args):
#     print("Drop sets: %s %s" % (args.action, args.target))
#
#
# def drop_collection(db, args):
#     print("Drop collection: %s %s" % (args.action, args.target))
#
#
# def drop_everything(db, args):
#     act = args.action
#     tgt = args.target
#     if tgt == all_targets:
#         for t in targets:
#             locals()["%s_%s" % t](db, t)
#     else:
#         locals()["load_%s" % tgt](db, tgt)


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
    args.func(db, args)

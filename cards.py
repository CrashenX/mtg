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
from pymongo import MongoClient, ASCENDING, TEXT
from bson.json_util import loads, dumps
from requests import get as httpget
from requests import codes
from sys import stdout

ACTIONS = ['get', 'load', 'dump', 'drop']
TARGETS = ['cards', 'sets', 'collection']
ALL_TARGETS = 'everything'
BACKUPS = 'backups/'
SYMBOLS = {'colors': {'B': '💀', 'U': '💧', 'G': '🌳', 'R': '🔥', 'W': '🌟'},
           'numbers': {'0': '⓪', '1': '①', '2': '②', '3': '③', '4': '④',
                       '5': '⑤', '6': '⑥', '7': '⑦', '8': '⑧', '9': '⑨',
                       '10': '⑩', '11': '⑪', '12': '⑫', '13': '⑬', '14': '⑭',
                       '15': '⑮', '16': '⑯', '17': '⑰', '18': '⑱', '19': '⑲',
                       'P': 'ϕ', 'X': 'ⓧ',
                       },
           'types': {'Artifact': '💎',
                     'Creature': '🐻',
                     'Enchantment': '📜',
                     'Instant': '⏱',
                     'Land': '🌄',
                     'Planeswalker': '🧙',
                     'Sorcery': '⏳',
                     'Tribal': '👪',
                     },
           'supertypes': {'Basic': '🅱️',
                          'Legendary': '👑',
                          'Snow': '🏔',
                          'World': '🌎',
                          }
           }


def gen_hdr(row):
    d = {}
    for k in row:
        d[k] = k
    return d


def format_row(row):
    def to_unicode(category, item):
        t = None
        try:
            t = SYMBOLS.get(category).get(item.capitalize())
        except:
            pass
        if t is None:
            return type
        return t

    def parse_cost(cost):
        if not cost:
            return ""
        elem = ""
        ucost = []
        for i in cost:
            if i in ['{', ' ']:
                continue
            if i in ['/', '}']:
                symbol = elem
                for t in ['numbers', 'colors']:
                    s = SYMBOLS[t].get(elem)
                    if s:
                        symbol = s
                ucost.append(symbol)
                elem = ""
                if i == '/':
                    ucost.append('/')
                continue
            elem += i
        return "".join(ucost)

    row['Type'] = "".join(
            [to_unicode('supertypes', t) for t in row.get('STypes', [])] +
            [to_unicode('types', t) for t in row.get('Types', [])])
    row['Cost'] = parse_cost(row.get('aCost'))


def pad_row(row):
    alen = len(row.get('Type'))
    ulen = len(row.get('Type').encode('UTF-8'))
    tpad = (7 - int((ulen+1)/4))
    if alen == ulen:
        tpad = 7
    return (str(row.get('∑')).rjust(2) + ' ' +
            row.get('Set').ljust(4) +
            row.get('Name').ljust(34) +
            row.get('Type').ljust(tpad) +
            row.get('Cost'))


def get(db, target):
    def target_get(db, target):
        first_time = True
        for i in getattr(db, target).aggregate([
            {'$group': {'_id': {'name': '$name', 'cfkey': '$cfkey',
                                'set': '$set'}, '∑': {'$sum': 1}}},
                {'$sort': {'_id.name': 1, '_id.set': 1}},
                {'$lookup': {'from': 'cards',
                             'localField': '_id.cfkey',
                             'foreignField': 'name',
                             'as': 'm'}},
                {'$project': {'_id': 0, '∑': 1,
                              'Name': '$_id.name',
                              'Set': '$_id.set',
                              'STypes': {'$arrayElemAt': ['$m.supertypes', 0]},
                              'Types': {'$arrayElemAt': ['$m.types', 0]},
                              'P/T': {'$concat': [
                                  {'$arrayElemAt': ['$m.power', 0]}, '/',
                                  {'$arrayElemAt': ['$m.toughness', 0]}]},
                              'aCost': {'$arrayElemAt': ['$m.manaCost', 0]}}},
                ]):
            format_row(i)
            if first_time:
                print(pad_row(gen_hdr(i)))
                first_time = False
            print(pad_row(i))

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
            print('Creating indexes...', end='')
            db.cards.create_index('name', unique=True)
            db.cards.create_index('convertedManaCost')
            db.cards.create_index([('name', TEXT), ('manaCost', TEXT),
                                   ('supertypes', TEXT), ('types', TEXT),
                                   ('rules', TEXT)])
            print("Done")

        def load_sets(db, target):
            load_mtgjson(db, target)
            print('Creating indexes...', end='')
            db.sets.create_index('code', unique=True, sparse=True)
            db.sets.create_index('name', unique=True)
            db.sets.create_index('releaseDate')
            db.sets.create_index([('name', TEXT)])
            print("Done")

        def load_collection(db, target):
            load_backup(db, target)
            print('Creating indexes...', end='')
            c = db.collection.create_index
            c('name')
            c('cfkey')
            c('set')
            c([('name', ASCENDING), ('set', ASCENDING)])
            c([('set', ASCENDING), ('name', ASCENDING)])
            c([('name', ASCENDING), ('cfkey', ASCENDING), ('set', ASCENDING)])
            c([('name', TEXT)])
            print("Done")

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

# NOTE: How to create a fast search with regex

# db.movies.find({
# $and:[{
#     $text: {
#         $search: "Moss Carrie-Anne"
#     }},{
#     cast: {
#         $elemMatch: {$regex: /Moss/, $regex: /Carrie-Anne/}}
#     }]}
# );

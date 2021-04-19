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
from os import get_terminal_size
from pymongo import MongoClient, ASCENDING, TEXT
from bson.json_util import loads, dumps
from requests import get as httpget
from requests import codes
from sys import stdout
from textwrap import wrap

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
        except Exception:
            pass
        if t is None:
            return '❓'
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

    typ = "".join(
            [to_unicode('supertypes', t) for t in row.get('STypes', [])] +
            [to_unicode('types', t) for t in row.get('Types', [])])
    if typ:
        row['Type'] = typ

    cost = parse_cost(row.get('aCost'))
    if cost:
        row['Cost'] = cost


def pad_row(row):
    t = ''
    start = 0
    if '∑' in row:
        t += str(row['∑']).rjust(2) + ' '
        start += 3
    if 'Date' in row:
        t += row['Date'].ljust(11)
        start += 11
    if 'Set' in row:
        t += row['Set'].ljust(5)
        start += 5
    if 'Name' in row:
        t += row['Name'].ljust(34)
        start += 34
    if 'Condition' in row:
        if row['Condition'] == 'Condition':
            t += 'Properties'.ljust(14)
            start += 14
        else:
            props = []
            c = row.get('Condition', '')
            if 'D' in c or 'P' in c:
                props.append(c)
            for p in ['Foil', 'Miscut', 'Promo', 'Textless']:
                if row.get(p):
                    props.append(p.lower())
            t += ", ".join(props).ljust(14)
            start += 14
    if 'P/T' in row:
        t += (row['P/T'] or '').ljust(6)
        start += 6
    if 'Type' in row:
        alen = len(row['Type'])
        ulen = len(row['Type'].encode('UTF-8'))
        tpad = (7 - int((ulen+1)/4))
        if alen == ulen:
            tpad = 7
        t += row['Type'].ljust(tpad)
        start += 7
    if 'Cost' in row:
        alen = len(row['Cost'])
        ulen = len(row['Cost'].encode('UTF-8'))
        cpad = (21 - int((ulen+1)/4))
        if alen == ulen:
            cpad = 21
        t += row['Cost'].ljust(cpad)
        start += 21
    if 'Text' in row:
        width = get_terminal_size().columns - start
        t += ('\n' + ' '*start).join(wrap(row['Text'], width)) + '\n'
    return t


def get(db, args):
    def target_get(db, target, search_terms):
        pipeline = []
        if target == 'collection':
            match = {}
            terms = []
            for s in search_terms:
                if s.lower() in ['foil', 'miscut', 'promo', 'textless']:
                    match[f"properties.{s}"] = True
                else:
                    terms.append(s)
            if len(terms) > 0:
                search = " ".join([f'"{s}"' for s in terms])
                match['$text'] = {'$search': f'{search}'}
            if match:
                pipeline.append({'$match': match})
            pipeline += [
                {'$group': {'_id': {'name': '$name',
                                    'cfkey': '$cfkey',
                                    'set': '$set',
                                    'condition': '$properties.condition',
                                    'foil': '$properties.foil',
                                    'miscut': '$properties.miscut',
                                    'promo': '$properties.promo',
                                    'textless': '$properties.textless',
                                    }, '∑': {'$sum': 1}}},
                {'$sort': {'_id.name': 1, '_id.set': 1}},
                {'$lookup': {'from': 'cards',
                             'localField': '_id.cfkey',
                             'foreignField': 'name',
                             'as': 'm'}},
                {'$project': {
                    '_id': 0, '∑': 1,
                    'Name': '$_id.name',
                    'Condition': '$_id.condition',
                    'Foil': '$_id.foil',
                    'Miscut': '$_id.miscut',
                    'Promo': '$_id.promo',
                    'Textless': '$_id.textless',
                    'Set': '$_id.set',
                    'STypes': {'$arrayElemAt': ['$m.supertypes', 0]},
                    'Types': {'$arrayElemAt': ['$m.types', 0]},
                    'P/T': {'$concat': [
                        {'$arrayElemAt': ['$m.power', 0]}, '/',
                        {'$arrayElemAt': ['$m.toughness', 0]}]},
                    'aCost': {'$arrayElemAt': ['$m.manaCost', 0]}}},
                ]
        elif target == 'cards':
            search = " ".join([f'"{s}"' for s in search_terms])
            pipeline = [
                {'$match': {'$text': {'$search': f'{search}'}}},
                {'$sort': {'name': 1}},
                {'$lookup': {'from': 'collection',
                             'localField': 'name',
                             'foreignField': 'cfkey',
                             'as': 'm'}},
                {'$project': {
                    '_id': 0, '∑': {'$size': '$m'},
                    'Name': '$name',
                    'STypes': '$supertypes',
                    'Text': '$text',
                    'Types': '$types',
                    'P/T': {'$concat': ['$power', '/', '$toughness']},
                    'aCost': '$manaCost',
                    }},
                ]
        elif target == 'sets':
            pipeline = [
                {'$match': {'$text': {'$search': f'{search}'}}},
                {'$sort': {'releaseDate': 1}},
                {'$project': {
                    '_id': 0,
                    'Date': '$releaseDate',
                    'Set': '$code',
                    'Name': '$name',
                    }},
                ]
        else:
            print('TOOD(jesse): Implement get %s' % target)
            return
        first_time = True
        for i in getattr(db, target).aggregate(pipeline):
            format_row(i)
            if first_time:
                print(pad_row(gen_hdr(i)))
                first_time = False
            print(pad_row(i))

    if args.target == ALL_TARGETS:
        for t in TARGETS:
            target_get(db, t)
    else:
        target_get(db, args.target, args.search_terms)


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
    urls = {'cards': 'https://mtgjson.com/api/v5/AtomicCards.json',
            'sets': 'https://mtgjson.com/api/v5/SetList.json',
            }
    try:
        r = httpget(urls[target])
    except Exception as e:
        emsg = str(e)
    if emsg == "" and r.status_code != codes.ok:
        emsg = "Received status code: %d" % r.status_code
    if emsg == "":
        if target == 'cards':
            for k, v in r.json()['data'].items():
                val = v[0]
                if len(v) == 2 and v[0].get('side', None):
                    if v[0]['side'] == 'a':
                        val['sideb'] = v[1]
                    else:
                        val = v[1]
                        val['sideb'] = v[0]
                elif len(v) > 1:
                    val = v[-1]
                val['name'] = val['name'].replace(' . . .', ' …')
                val.pop('foreignData', None)
                getattr(db, target).insert_one(val).inserted_id
        else:
            for v in r.json()['data']:
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
            stdout.flush()
            db.cards.create_index('name', unique=True)
            db.cards.create_index('convertedManaCost')
            db.cards.create_index([('convertedManaCost', TEXT), ('name', TEXT),
                                   ('manaCost', TEXT), ('text', TEXT),
                                   ('type', TEXT)])
            print("Done")

        def load_sets(db, target):
            load_mtgjson(db, target)
            print('Creating indexes...', end='')
            stdout.flush()
            db.sets.create_index('code', unique=True, sparse=True)
            db.sets.create_index('name', unique=True)
            db.sets.create_index('releaseDate')
            db.sets.create_index([('name', TEXT), ('releaseDate', TEXT)])
            print("Done")

        def load_collection(db, target):
            load_backup(db, target)
            print('Creating indexes...', end='')
            stdout.flush()
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
            p.add_argument('search_terms',
                           metavar='SEARCH_TERM',
                           type=str,
                           help="Limit results by search terms",
                           nargs='*')
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

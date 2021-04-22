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
from datetime import date
from os import get_terminal_size
from pymongo import MongoClient, ASCENDING, TEXT
from bson.json_util import loads, dumps
from requests import get as httpget
from requests import codes
from sys import stdout
from textwrap import wrap
from typing import List

ACTIONS = ['add', 'get', 'load', 'dump', 'drop', 'remove']
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
                     'Summon': '🐻',
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
    if 'Properties' in row:
        prop = row['Properties']
        if prop == 'Properties':
            t += 'Properties'.ljust(15)
            start += 15
        else:
            props = []
            c = prop.get('Condition', '')
            if 'D' in c or 'P' in c:
                props.append(c)
            for p in ['foil', 'miscut', 'promo', 'textless']:
                if prop.get(p):
                    props.append(p.lower())
            t += ", ".join(props).ljust(15)
            start += 15
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


def add(db, args):
    def add_cards(db, n: int, name: str, cset: str, attr: List[str]):
        print('Adding cards not currently supported')

    def add_sets(db, n: int, name: str, cset: str, attr: List[str]):
        print('Adding sets not currently supported')

    def add_collection(db, n: int, name: str, cset: str, attr: List[str]):
        query = {'name': name}
        code = cset.upper()
        r = getattr(db, 'cards').find_one(query)
        if not r:
            print(f"Card not found. name={name}")
            return
        p = r.get('printings', {})
        if code not in p:
            print(f"Invalid set for card. set={code} printings={p}")
            return
        card = {'name': r['name'],
                'set': code,
                'properties': {
                    'condition': 'Unknown',
                    'foil': False,
                    'miscut': False,
                    'promo': False,
                    'textless': False,
                    }
                }
        for a in attr:
            card['properties'][a] = True
        have = [c for c in getattr(db, 'collection').find(card)]
        print(f"Adding card(s). name={name} have={len(have)} adding={n}")
        card['added'] = str(date.today())
        for i in range(n):
            getattr(db, 'collection').insert_one(card)
            card.pop('_id', None)  # Allow duplicate card entry
        p = r.get('power')
        t = r.get('toughness')
        pt = f"{p}/{t}" if p and t else None
        card.pop('added', None)
        count = getattr(db, 'collection').count_documents(card)
        card = {'∑': count,
                'aCost': r['manaCost'],
                'Name': r['name'],
                'Properties': card['properties'],
                'P/T': pt,
                'Set': card['set'],
                'STypes': r['supertypes'],
                'Text': r['text'],
                'Types': r['types'],
                }
        format_row(card)
        print(pad_row(gen_hdr(card)))
        print(pad_row(card))

    a = args
    if a.target == ALL_TARGETS:
        for t in TARGETS:
            locals()["add_%s" % t](db, a.n, a.name, a.set, a.attr)
    else:
        locals()["add_%s" % args.target](db, a.n, a.name, a.set, a.attr)


def remove(db, args):
    def remove_cards(db, n: int, name: str, cset: str, attr: List[str]):
        print('Removing cards not currently supported')

    def remove_sets(db, n: int, name: str, cset: str, attr: List[str]):
        print('Removing sets not currently supported')

    def remove_collection(db, n: int, name: str, cset: str, attr: List[str]):
        print('ToDo: Change this code to remove instead of add')
        query = {'name': name}
        code = cset.upper()
        r = getattr(db, 'cards').find_one(query)
        if not r:
            print(f"Card not found. name={name}")
            return
        p = r.get('printings', {})
        if code not in p:
            print(f"Invalid set for card. set={code} printings={p}")
            return
        card = {'name': r['name'],
                'set': code,
                'properties': {
                    'condition': 'Unknown',
                    'foil': False,
                    'miscut': False,
                    'promo': False,
                    'textless': False,
                    }
                }
        for a in attr:
            card['properties'][a] = True
        have = [c for c in getattr(db, 'collection').find(card)]
        print(f"Adding card(s). name={name} have={len(have)} adding={n}")
        card['added'] = str(date.today())
        for i in range(n):
            getattr(db, 'collection').insert_one(card)
            card.pop('_id', None)  # Allow duplicate card entry
        p = r.get('power')
        t = r.get('toughness')
        pt = f"{p}/{t}" if p and t else None
        card.pop('added', None)
        count = getattr(db, 'collection').count_documents(card)
        card = {'∑': count,
                'aCost': r['manaCost'],
                'Name': r['name'],
                'Properties': card['properties'],
                'P/T': pt,
                'Set': card['set'],
                'STypes': r['supertypes'],
                'Text': r['text'],
                'Types': r['types'],
                }
        format_row(card)
        print(pad_row(gen_hdr(card)))
        print(pad_row(card))

    a = args
    if a.target == ALL_TARGETS:
        for t in TARGETS:
            locals()["remove_%s" % t](db, a.n, a.name, a.set, a.attr)
    else:
        locals()["remove_%s" % args.target](db, a.n, a.name, a.set, a.attr)


def get(db, args):
    def get_collection_pipeline(search_terms):
        pipeline = []
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
            {'$group': {'_id': {'name': '$name', 'set': '$set',
                                'condition': '$properties.condition',
                                'foil': '$properties.foil',
                                'miscut': '$properties.miscut',
                                'promo': '$properties.promo',
                                'textless': '$properties.textless',
                                }, '∑': {'$sum': 1}}},
            {'$sort': {'_id.name': 1, '_id.set': 1}},
            {'$lookup': {'from': 'cards',
                         'localField': '_id.name',
                         'foreignField': 'name',
                         'as': 'm'}},
            {'$project': {
                '_id': 0, '∑': 1,
                'Name': '$_id.name',
                'Condition': '$_id.condition',
                'Properties': {'foil': '$_id.foil',
                               'miscut': '$_id.miscut',
                               'promo': '$_id.promo',
                               'textless': '$_id.textless',
                               },
                'Set': '$_id.set',
                'STypes': {'$arrayElemAt': ['$m.supertypes', 0]},
                'Types': {'$arrayElemAt': ['$m.types', 0]},
                'P/T': {'$concat': [
                    {'$arrayElemAt': ['$m.power', 0]}, '/',
                    {'$arrayElemAt': ['$m.toughness', 0]}]},
                'aCost': {'$arrayElemAt': ['$m.manaCost', 0]}}},
            ]
        return pipeline

    def get_cards_pipeline(search_terms):
        search = " ".join([f'"{s}"' for s in search_terms])
        pipeline = [
            {'$match': {'$text': {'$search': f'{search}'}}},
            {'$sort': {'name': 1}},
            {'$lookup': {'from': 'collection',
                         'localField': 'name',
                         'foreignField': 'name',
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
        return pipeline

    def get_sets_pipeline(search_terms):
        search = " ".join([f'"{s}"' for s in search_terms])
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
        return pipeline

    def print_results(db, target, pipeline):
        first_time = True
        for i in getattr(db, target).aggregate(pipeline):
            format_row(i)
            if first_time:
                print(pad_row(gen_hdr(i)))
                first_time = False
            print(pad_row(i))

    if args.target == ALL_TARGETS:
        for t in TARGETS:
            print(f"{t.capitalize()}:")
            pipeline = locals()["get_%s_pipeline" % t](args.search_terms)
            print_results(db, t, pipeline)
            print()
    else:
        pipeline = locals()["get_%s_pipeline" % args.target](args.search_terms)
        print_results(db, args.target, pipeline)


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
        db.sets.create_index([('code', TEXT), ('name', TEXT),
                              ('releaseDate', TEXT)])
        print("Done")

    def load_collection(db, target):
        load_backup(db, target)
        print('Creating indexes...', end='')
        stdout.flush()
        c = db.collection.create_index
        c('name')
        c('set')
        c([('name', ASCENDING), ('set', ASCENDING)])
        c([('set', ASCENDING), ('name', ASCENDING), ('set', ASCENDING)])
        c([('name', TEXT)])
        print("Done")

    drop(db, args)
    if args.target == ALL_TARGETS:
        for t in TARGETS:
            locals()["load_%s" % t](db, t)
    else:
        locals()["load_%s" % args.target](db, args.target)


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
    def pint(v):
        i = int(v)
        if i <= 0:
            raise ArgumentTypeError("%s is not a positive integer" % v)
        return i

    parser = ArgumentParser(description='Manage MTG Collection')
    subparsers = parser.add_subparsers(metavar='CMD')

    def aa(p, *args, **kwargs):
        p.add_argument(*args, **kwargs)

    for cmd in ACTIONS:
        p = subparsers.add_parser(cmd, help='%s mtg data' % cmd)
        tgts = TARGETS + [ALL_TARGETS]
        aa(p, 'target', metavar='TARGET', type=str, choices=tgts,
           help="{%s}" % '|'.join(tgts))
        p.set_defaults(func=locals()[cmd])
        if cmd == 'get':
            aa(p, 'search_terms', metavar='SEARCH_TERM', type=str, nargs='*',
               help="Limit results by search terms")
        elif cmd in ['add', 'remove']:
            aa(p, 'n', metavar='QUANTITY', type=pint, help='Quantity')
            aa(p, 'name', metavar='NAME', type=str, help="Target name")
            aa(p, 'set', metavar='SET', type=str, help="Set Code")
            aa(p, 'attr', metavar='ATTR', type=str, help="Attributes",
               choices=['foil', 'miscut', 'promo', 'textless', []], nargs='*')

    subparsers.required = True
    autocomplete(parser)
    args = parser.parse_args()
    client = MongoClient()
    db = client.mtg
    args.func(db, args)

# NORM|FOIL|PROMO|TEXTLESS|MISCUT|EDITION|RARITY|NAME
import datetime
from os import SEEK_SET
today = datetime.date.today()


def get_row(foil, promo, textless, miscut):
    return ('    {"added": "%s", "name": "%s", "set": "%s", "properties": '
            '{"condition": "Unknown", "foil": %s, "promo": %s, "textless": %s'
            ', "miscut": %s}},\n' %
            (str(today), name, mset, foil, promo, textless, miscut))


with open('cards.db', 'r') as nf, open('backups/collection.json', 'w') as of:
    inp = nf.read()
    count = 0
    of.write('[\n')
    for line in inp.split('\n'):
        if count == 0 or line == '\n' or line == '':
            count += 1
            continue
        values = line.split('|')
        norm = values[0]
        foil = values[1]
        prom = values[2]
        text = values[3]
        msct = values[4]
        mset = values[5]
        name = values[7]
        for i in range(int(norm)):
            of.write(get_row("false", "false", "false", "false"))
        for i in range(int(foil)):
            of.write(get_row("false", "false", "false", "false"))
        for i in range(int(prom)):
            of.write(get_row("false", "true", "false", "false"))
        for i in range(int(text)):
            of.write(get_row("false", "false", "true", "false"))
        for i in range(int(msct)):
            of.write(get_row("false", "false", "false", "true"))
    of.seek(of.tell() - 2, SEEK_SET)
    of.write('\n]')

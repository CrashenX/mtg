# MTG Collection Management

## Getting Started

    python3 -m venv venv
    venv/bin/pip install -U pip
    venv/bin/pip install -r requirements.txt

### Tab Completion

Docs: https://argcomplete.readthedocs.io/en/latest/index.html

    venv/bin/register-python-argcomplete cards>~/.completions/cards.sh
    complete | grep cards # if you see: complete -F _minimal ./cards
    complete -r ./cards   # then run this to remove
    source ~/.completions/cards.sh
    complete | grep cards # should see: complete -o default -o nospace -F \
                          #             _python_argcomplete cards

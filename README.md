# MTG Collection Management

## Getting Started

    python3 -m venv venv
    venv/bin/pip install -U pip
    venv/bin/pip install -r requirements.txt

### Tab Completion

Docs: https://argcomplete.readthedocs.io/en/latest/index.html

    venv/bin/register-python-argcomplete cards.py>~/.bash_completion.d/cards.sh
    complete | grep cards   # if you see: complete -F _minimal ./cards.py
    complete -r ./cards.py  # then run this to remove
    source ~/.bash_completion.d/cards.sh
    complete | grep cards   # should see: complete -o default -o nospace -F \
                            #             _python_argcomplete cards.py

NB: You might need to create `~/.bash_completion` and source in `~/.bashrc`

    for bcfile in ~/.bash_completion.d/* ; do
        [ -f "$bcfile" ] && . $bcfile
    done

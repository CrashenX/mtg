# MTG Collection Management

## Getting Started

    python3 -m venv venv
    venv/bin/pip install -U pip
    venv/bin/pip install -r requirements.txt

### Tab Completion

    venv/bin/register-python-argcomplete cards.py>~/.bash_completion.d/cards.sh

Docs: https://argcomplete.readthedocs.io/en/latest/index.html

NB: You might need to create `~/.bash_completion` and source in `~/.bashrc`

    for bcfile in ~/.bash_completion.d/* ; do
        [ -f "$bcfile" ] && . $bcfile
    done

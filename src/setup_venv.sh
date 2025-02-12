#! /bin/bash

VENV="ecdsa_env"

if [ ! -d "$VENV" ]; then
  pwd
  echo "$VENV does not exist in current directory, creating it"
  python3 -m venv $VENV
fi

if [ ! -d "$VENV" ]; then
  echo "failed to create $VENV in current directory, exiting"
  exit 1
fi

source $VENV/bin/activate

pip install pycryptodome
pip install numpy
pip install matplotlib
pip install pandas
pip install seaborn

echo "--- use following command to enter venv: ---"
echo "source $VENV/bin/activate"
# deactivate
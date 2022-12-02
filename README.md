Python library for UTEL SMSG format
Work in progress.


Build/Install
============
Building requires a native toolchain to build C++ code.

Create an appropriate virtualenv and run

    pip install -r requirements.txt
    python setup.py install

Look at examples/


Build a wheel:
  python setup.py bdist_wheel

This creates a python wheel in the dist/ folder that can be moved around
and install with
  pip install /path/to/xxx.whl

(The .whl is platform specific)


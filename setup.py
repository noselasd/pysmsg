import setuptools
from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension


extensions = [
    Extension('pysmsg', ['src/*.pyx', 'src/smsg.cpp'],
              extra_compile_args=['-std=c++17'],
              language='c++',
              ),
]

setup(
    name='pysmsg',
    version="0.0.1",
    description="UTEL SMSG data format parser",
    author="Nils Olav Selåsdal",
    python_requires='>=3.9',
    ext_modules=cythonize(extensions, language_level = "3"),
)

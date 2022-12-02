from setuptools import setup
from Cython.Build import cythonize
from setuptools.extension import Extension


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
    setup_requires = ['setuptools>=59.6.0', 'Cython>=0.29.32'],
)

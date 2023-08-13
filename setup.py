#!/usr/bin/env python

from setuptools import setup, find_packages
import re
from codecs import open

VERSIONFILE = "facturx/_version.py"
verstrline = open(VERSIONFILE, "rt").read()
VSRE = r"^__version__ = ['\"]([^'\"]*)['\"]"
mo = re.search(VSRE, verstrline, re.M)
if mo:
    verstr = mo.group(1)
else:
    raise RuntimeError("Unable to find version string in %s." % (VERSIONFILE))

with open("README.rst", "r", "utf-8") as f:
    readme = f.read()

with open("requirement.txt", "r", "utf-8") as reqf:
    install_requires = [r.strip() for r in reqf.read().splitlines()]

setup(
    name='factur-x',
    version=verstr,
    author='Alexis de Lattre',
    author_email='alexis.delattre@akretion.com',
    url='https://github.com/akretion/factur-x',
    description='Factur-X and Order-X: electronic invoicing and ordering standards',
    long_description=readme,
    license='BSD',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'License :: OSI Approved :: BSD License',
        "Operating System :: OS Independent",
        "Topic :: Office/Business :: Financial :: Accounting",
    ],
    keywords='e-invoice ZUGFeRD Factur-X Order-X e-procurement',
    python_requires=">=3.6",
    packages=find_packages(),
    install_requires=install_requires,
    include_package_data=True,
    scripts=[
        'bin/facturx-pdfgen',
        'bin/facturx-pdfextractxml',
        'bin/facturx-xmlcheck',
        'bin/facturx-webservice',
        ],
    zip_safe=False,
)

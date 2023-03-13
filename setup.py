#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup, find_packages
import re

VERSIONFILE = "facturx/_version.py"
verstrline = open(VERSIONFILE, "rt").read()
VSRE = r"^__version__ = ['\"]([^'\"]*)['\"]"
mo = re.search(VSRE, verstrline, re.M)
if mo:
    verstr = mo.group(1)
else:
    raise RuntimeError("Unable to find version string in %s." % (VERSIONFILE))

setup(
    name='factur-x',
    version=verstr,
    author='Alexis de Lattre',
    author_email='alexis.delattre@akretion.com',
    url='https://github.com/akretion/factur-x',
    description='Factur-X and Order-X: electronic invoicing and ordering standards',
    long_description=open('README.rst').read(),
    license='BSD',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'License :: OSI Approved :: BSD License',
        "Operating System :: OS Independent",
        "Topic :: Office/Business :: Financial :: Accounting",
    ],
    keywords='e-invoice ZUGFeRD Factur-X Order-X e-procurement',
    packages=find_packages(),
    install_requires=[r.strip() for r in
                      open('requirement.txt').read().splitlines()],
    include_package_data=True,
    scripts=[
        'bin/facturx-pdfgen',
        'bin/facturx-pdfextractxml',
        'bin/facturx-xmlcheck',
        'bin/facturx-webservice',
        ],
    zip_safe=False,
)

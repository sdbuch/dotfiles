#!/usr/bin/env python
# -*- coding: utf-8 -*-

# imports
import numpy as np
import numpy.linalg as npla
from numpy.random import default_rng
import scipy as sp
import scipy.io as sio
import matplotlib.pyplot as plt
import time

"""Utility functions to import in my scripts."""

class Timer(object):
    def __init__(self, name=None):
        self.name = name

    def __enter__(self):
        self.tstart = time.time()

    def __exit__(self, type, value, traceback):
        if self.name:
            print('[%s]' % self.name,)
        print('Elapsed: %s' % (time.time() - self.tstart))

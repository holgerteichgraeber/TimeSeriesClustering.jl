#!/data/cees/hteich/libraries/miniconda/bin/ python
# coding: utf-8


import time
import os,sys
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import csv
import pandas as pd
import pdb
from copy import deepcopy


here = os.path.dirname(os.path.realpath(__file__))
dba_path = os.path.realpath(os.path.join(here,".."))
sys.path.append(dba_path)
print dba_path
import dba
from dba import DBA


def read_CA_el_data_CSV(path_to_data):
    temp = []
    with open(path_to_data, 'rb') as csvfile:
        read = csv.reader(csvfile)
        for row in read:
            temp.append(row) #Don't know how many entries, so use list instead of numpyarray
    obs = np.array(temp)
    return obs[1:].astype(np.float)  # start from second (1) because first is filename

##################################################################
''' Main Function starts here '''
##################################################################
if __name__ == '__main__':
    # argv[1] -> either CA or GER
    if len(sys.argv) == 1 or len(sys.argv) >2:
        sys.exit("Not the correct number of input arguments")
    else:
        if sys.argv[1] == "GER" or sys.argv[1] == "CA":
            region = sys.argv[1]
            print "Region: ", sys.argv[1], "\n"
        else:
            sys.exit("Region not defined: " + sys.argv[2])

    plt.close("all")
    tic = time.time()

    # load electricity price data - call el_CA_2015 for historic reasons
    # \TODO change el_CA_2015 and other variable names to more generic name.
    if region == "CA":
        el_CA_2015 = read_CA_el_data_CSV(os.path.realpath(os.path.join(here,"..","..","..","data","el_prices","CA_2015_elPriceStanford.csv")))
        reg_str = "" # prefix for datanaming later
    elif region == "GER":
        el_CA_2015 = read_CA_el_data_CSV(os.path.realpath(os.path.join(here,"..","..","..","data","el_prices","GER_2015_elPrice.csv")))
        reg_str = "GER_"

    el_CA_2015_resh = np.reshape(el_CA_2015, (el_CA_2015.size/24, 24))
    # make list of input sequences
    el_price_list = []
    max_seq = 10
    for i in range(max_seq):
        el_price_list.append(el_CA_2015_resh[i,:].reshape(24,1))   # alternativiely, use np.atleast_2d

    niter=15
    dba = DBA(niter, verbose=True, tol=1e-5)


    t1 = time.clock()
    #pdb.set_trace()
    dba_avg = dba.compute_average(el_price_list, nstarts=1,dba_length=24)
    t2 = time.clock()

    print 'DBA algorithm took', t2 - t1, 'seconds. \n'
    print dba_avg, "\n"

    f = plt.figure()
    for i in range(max_seq):
        plt.plot(el_price_list[i],color="0.75")
    plt.plot(dba_avg,color="red",label="dtw dba")
    plt.plot(np.mean(el_price_list,0),color="blue",label="euc")
    plt.legend()
    f.show()

    # normalized clustering


    plt.show()

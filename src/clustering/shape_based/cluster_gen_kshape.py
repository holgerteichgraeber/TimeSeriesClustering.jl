#!/data/cees/hteich/libraries/miniconda/bin/ python
# coding: utf-8
# This file currently only works on LINUX based systems


from time import time
import os,sys
import numpy as np
import csv
import pickle
from copy import deepcopy

# TODO: possibly not necessary anymore if kshape is installed using pip kshape install
sys.path.append('/home/hteich/ClustForOpt/src/clust_algorithms')
import kshape
from kshape import _kshape, zscore

print(os.getcwd()) # if file is here can import


def read_CA_el_data_CSV(path_to_data):
    temp = []
    with open(path_to_data, 'rb') as csvfile:
         read = csv.reader(csvfile)
         for row in read:
            temp.append(row) #Don't know how many entries, so use list instead of numpyarray
    obs = np.array(temp)
    return obs[1:].astype(np.float)  # start from second (1) because first is filename



def normalize_meansdv(price_dat_resh): 
    price_dat_norm = np.zeros(np.shape(price_dat_resh))
    hourly_mean = np.mean(price_dat_resh)
    hourly_sdv = np.std(price_dat_resh)
    price_dat_norm = (price_dat_resh-hourly_mean)/hourly_sdv
    return price_dat_norm,hourly_mean,hourly_sdv

def normalize_by_hour_meansdv(price_dat_resh):
    price_dat_norm = np.zeros(np.shape(price_dat_resh))
    hourly_mean = np.zeros(np.shape(price_dat_resh)[1])
    hourly_sdv = np.zeros(np.shape(price_dat_resh)[1])
    for i in range(np.shape(price_dat_resh)[1]):
        hourly_mean[i] = np.mean(price_dat_resh[:,i])
        price_dat_norm[:,i] = price_dat_resh[:,i] - hourly_mean[i]
        hourly_sdv[i] = np.std(price_dat_resh[:,i])
        if hourly_sdv[i] ==0:
            hourly_sdv[i] =1
        price_dat_norm[:,i] = price_dat_norm[:,i]/hourly_sdv[i]
    return price_dat_norm, hourly_mean, hourly_sdv

def normalize_by_seq_meansdv(price_dat_resh):
    price_dat_norm = np.zeros(np.shape(price_dat_resh))
    seq_mean = np.zeros(np.shape(price_dat_resh)[0])
    seq_sdv = np.zeros(np.shape(price_dat_resh)[0])
    for i in range(np.shape(price_dat_resh)[0]):
        seq_mean[i] = np.mean(price_dat_resh[i,:])
        price_dat_norm[i,:] = price_dat_resh[i,:] - seq_mean[i]
        seq_sdv[i] = np.std(price_dat_resh[i,:],ddof=1)
        if seq_sdv[i] ==0:
            seq_sdv[i] =1
        price_dat_norm[i,:] = price_dat_norm[i,:]/seq_sdv[i]
    return price_dat_norm, seq_mean, seq_sdv


def run_kshape(el_resh, n_clusters, n_init=1,max_iter=100,n_jobs=1,region='',normalize=True):  # el_resh is (days,24)

    res = _kshape(el_resh, n_clusters, n_init=n_init,max_iter=max_iter, n_jobs=n_jobs,normalize=normalize)
    k_shape_labels = deepcopy(res['labels'])   #vector with kshape class for each datapoint
    k_shape_cluster_centers = deepcopy(res['centroids'])
    tot_dist = deepcopy(res['distance'])
    weights = np.zeros(n_clusters)
    SSE =0
    SSE_daily = np.zeros(k_shape_labels.size)
    cluster_closest_day = np.zeros(n_clusters) # day number of closest day
    SSE_closest_day = np.ones(n_clusters)*1e25 # np.zeros(n_clusters)
    dist_closest_day = np.ones(n_clusters)*1e25
    for i in range(k_shape_labels.size):
        weights[k_shape_labels[i]] += 1
        for j in range(el_resh.shape[1]):
            SSE_daily[i] += (el_resh[i,j] - k_shape_cluster_centers[k_shape_labels[i],j])**2
            SSE += (el_resh[i,j] - k_shape_cluster_centers[k_shape_labels[i],j])**2
        #if SSE_daily[i] < SSE_closest_day[k_shape_labels[i]]: # calc closest day
        # disable closest day in kshape
        #if dist_daily[i] < dist_closest_day[k_shape_labels[i]]:
            #cluster_closest_day[k_shape_labels[i]] = i
            #SSE_closest_day[k_shape_labels[i]] = SSE_daily[i]
            # add dist_closest_day here 
    weights = weights/k_shape_labels.size # calc weights
    # sort in descending order
    ind_w = np.argsort(weights)[::-1] # ::-1 reverse order - descending
    weights = np.sort(weights)[::-1]
    k_shape_cluster_centers = k_shape_cluster_centers[ind_w]
    #cluster_closest_day = cluster_closest_day[ind_w]
    for i in range(k_shape_labels.size):
        k_shape_labels[i] = np.where(ind_w == k_shape_labels[i])[0][0]
    # save to pickle
    pickle.dump(res['centroids_all'],open('outfiles/pickle_save/'+ region +'_centroids_kshape_'+str(n_clusters)+'.pkl',"wb"))
    pickle.dump(res['labels_all'],open('outfiles/pickle_save/'+ region +'labels_kshape_'+str(n_clusters)+'.pkl',"wb"))
    pickle.dump(res['distance_all'],open('outfiles/pickle_save/'+ region +'distance_kshape_'+str(n_clusters)+'.pkl',"wb"))
    pickle.dump(res['iterations'],open('outfiles/pickle_save/'+ region +'iterations_kshape_'+str(n_clusters)+'.pkl',"wb"))


    return {'centers':k_shape_cluster_centers, 'weights':weights ,'SSE':SSE, 'labels':k_shape_labels, 'closest_day': cluster_closest_day }


##################################################################
''' Main Function starts here '''
##################################################################
if __name__ == '__main__':
    # argv[1] -> either CA or GER
    if len(sys.argv) <= 2 or len(sys.argv) >3:
        sys.exit("Not the correct number of input arguments")
    else:
        if sys.argv[1] == "GER" or sys.argv[1] == "CA":
            region = sys.argv[1]
            print "Region: ", sys.argv[1], "\n"
        else:
            sys.exit("Region not defined: " + sys.argv[2])
        scope = sys.argv[2]
        print "Scope: ", sys.argv[2], "\n"


    tic_begin = time()


    ### SETTINGS ###
    n_rand_km = 1000#  random starting points for kmeans
    min_k =1
    max_k=min_k+9   # if we want to cluster 8,9, min_k=8, max_k=8+2
    n_k = np.arange(min_k,max_k)
    showfigs = False  
    n_jobs = -1  #1 default, -1 as many cores as available
    max_iter = 1000
    plots = False
    ##############

    # load electricity price data - call el_CA_2015 for historic reasons
    # \TODO change el_CA_2015 and other variable names to more generic name.
    if region == "CA":
        el_CA_2015 = read_CA_el_data_CSV('/data/cees/hteich/clustering/data/el_prices/CA_2015_elPriceStanford.csv')
        reg_str = "" # prefix for datanaming later
    elif region == "GER":
        el_CA_2015 = read_CA_el_data_CSV('/data/cees/hteich/clustering/data/el_prices/GER_2015_elPrice.csv')
        reg_str = "GER_"

    el_CA_2015_norm_meansdv_hourly,mean_hourly,sdv_hourly= normalize_by_hour_meansdv(el_CA_2015_resh)
    el_CA_2015_norm_meansdv,mean_seq,sdv_seq= normalize_by_seq_meansdv(el_CA_2015_resh)
    el_CA_2015_full_meansdv,mean_full,sdv_full= normalize_meansdv(el_CA_2015_resh)

    ### kshape - norm_data mean sdv - z-normalized
    SSE_kshape = np.zeros(n_k.size)
    cluster_centers_kshape =[]
    labels_kshape = []
    wt_kshape =[]
    cluster_closest_day_kshape = []
    i=0
    for k in n_k:
        i = i+1
        tic = time()
        res=[]
        if scope == "full":
            res = run_kshape(el_CA_2015_full_meansdv, k,n_init=n_rand_km, max_iter=max_iter, n_jobs=n_jobs,region=region,normalize=False)
        elif scope == "hourly":
            res = run_kshape(el_CA_2015_norm_meansdv_hourly, k,n_init=n_rand_km, max_iter=max_iter, n_jobs=n_jobs,region=region,normalize=False)
        elif scope == "sequence":
            res = run_kshape(el_CA_2015_norm_meansdv, k,n_init=n_rand_km, max_iter=max_iter, n_jobs=n_jobs,region=region,normalize=True)
        else:
            print "Scope _ ", scope, " _ not defined. \n"
        toc = time()
        sys.stdout.write("k=" + str(k) + " took " + str(toc - tic) + " s  \n" ) # on cluster, print seems to be omitted in out
        
        sys.stdout.flush() # empty the buffer
    
    # time print
    toc_end = time()
    sys.stdout.write("total kshape clustering took: " + str(toc_end - tic_begin) + " s  \n" ) # on cluster, print seems to be omitted in out
    



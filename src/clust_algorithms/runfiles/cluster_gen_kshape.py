#!/data/cees/hteich/libraries/miniconda/bin/ python
# coding: utf-8
# THIS FILE SHOULD BE INDEPENDENT OF ITS LOCATION --> Only full path references
# This file currently only works on LINUX based systems
# Runs kshape and kshape saves local results in normalized space in pkl. This file also saves the best centroids as txt, but undoing the normalization may not be up to date. Possibly delete (TODO)


from time import time
import os,sys
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
from sklearn import metrics
from sklearn.cluster import KMeans
from sklearn.cluster import AgglomerativeClustering
import csv
import calendar
import pandas as pd
import pdb
import pickle
from copy import deepcopy

sys.path.append('/data/cees/hteich/clustering/src/clust_algorithms')
import kshape
from kshape import _kshape, zscore

print(os.getcwd()) # if file is here can import
#plt.interactive(False)


def read_CA_el_data_CSV(path_to_data):
    temp = []
    with open(path_to_data, 'rb') as csvfile:
         read = csv.reader(csvfile)
         for row in read:
            temp.append(row) #Don't know how many entries, so use list instead of numpyarray
    obs = np.array(temp)
    return obs[1:].astype(np.float)  # start from second (1) because first is filename

# Must input np.array (vector)
def conv_EUR_to_USD(EUR):
    EUR_to_USD = 1.109729 # 2015
    USD = np.zeros(EUR.size)
    for i in range(EUR.size):
        USD[i] = EUR[i]*EUR_to_USD
    return USD

def manipulate_weather_data(data_utc):  # year 2014 ; input np.array ; make data PST from UTC and accoutn for daylight saving time
    # -8 hours time difference in winter, -7 hours of time difference in summer
    data_intermed = data_utc[8:]  # take out first 8 hours (part of the last year)
    data_intermed = data_intermed[:-24 + 8]  # take out last day (only partly available)
    num_days = 0
    for i in range(3):  # Daylight saving time march 9, nov 2
        num_days += calendar.monthrange(2014, i + 1)[1]
    num_days += 8  # march 9
    num_hours = num_days * 24 + 2
    data_intermed = np.insert(data_intermed, num_hours, data_intermed[num_hours])

    num_days = 0
    for i in range(11):
        num_days += calendar.monthrange(2014, i + 1)[1]
    num_days += 1  # nov2
    num_hours = num_days * 24 + 3  # delete the second one
    data_intermed = np.delete(data_intermed, num_hours, 0)
    return data_intermed


def load_wind_data():
    filepath_wind = "weather_data/Altamount_wind.csv"
    wind_data = pd.read_csv(filepath_wind, header=1, names=["Time", "Power [kW]", "Speed [m/s]"])
    wind_power = wind_data["Power [kW]"].values  # kW
    wind_speed = wind_data["Speed [m/s]"].values  # m/s
    wind_power = manipulate_weather_data(wind_power)
    wind_speed = manipulate_weather_data(wind_speed)
    return {'power': wind_power, 'speed': wind_speed}


def load_solar_data():
    filepath_pv = "weather_data/Altamount_PV.csv"
    pv_data = pd.read_csv(filepath_pv, header=1, names=["Time", "Power", "Direct", "Diffuse", "Temp"])
    pv_dict = {}
    for column in pv_data:
        pv_dict[column] = manipulate_weather_data(pv_data[column].values)
    return pv_dict



def normalize_by_hour_01(price_dat_resh): # normalize such that maximum is 1
    price_dat_norm = np.zeros(np.shape(price_dat_resh))
    hourly_max = np.zeros(np.shape(price_dat_resh)[1])
    for i in range(np.shape(price_dat_resh)[1]):
        hourly_max[i] = np.amax(price_dat_resh[:, i])
        if hourly_max[i] ==0:
            hourly_max[i] =1
        price_dat_norm[:, i] = price_dat_resh[:, i] / hourly_max[i]
    return price_dat_norm, hourly_max

def normalize_01(price_dat_resh): # normalize such that maximum is 1
    price_dat_norm = np.zeros(np.shape(price_dat_resh))
    hourly_max = np.zeros(np.shape(price_dat_resh)[1])
    for i in range(np.shape(price_dat_resh)[1]):
        hourly_max[i] = np.amax(price_dat_resh)
        if hourly_max[i] ==0:
            hourly_max[i] =1
        price_dat_norm[:, i] = price_dat_resh[:, i] / hourly_max[i]
    return price_dat_norm, hourly_max

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

def merge_norm_data(data1,data2,data3):
    return 0

def plot_monthly_price(price_dat):
    ind = 0
    price_dat_monthly = []
    for t in range(0,12):
        ind_end = ind + (calendar.monthrange(2015,t+1)[1])*24-1
        price_dat_monthly.append(price_dat[ind:ind_end])
        f = plt.figure()
        plt.plot(price_dat_monthly[t])
        plt.ylabel('$/MWh')
        plt.title('Month: ' + str(t+1))
        f.show()
        ind = ind_end +1
    #plt.show()
    return price_dat_monthly



def run_kmeans(el_resh, n_clusters, n_init ):  # el_resh is (days,24)
    kmeans = KMeans(n_clusters = n_clusters, n_init = n_init, init = 'k-means++').fit(el_resh)
    k_means_labels = kmeans.labels_   #vector with kmeans class for each datapoint
    k_means_cluster_centers = kmeans.cluster_centers_
    weights = np.zeros(n_clusters)
    SSE =0
    SSE_daily = np.zeros(k_means_labels.size)
    cluster_closest_day = np.zeros(n_clusters) # day number of closest day
    SSE_closest_day = np.ones(n_clusters)*1e25 # np.zeros(n_clusters)
    for i in range(k_means_labels.size):
        weights[k_means_labels[i]] += 1
        for j in range(el_resh.shape[1]):
            SSE_daily[i] += (el_resh[i,j] - k_means_cluster_centers[k_means_labels[i],j])**2
            SSE += (el_resh[i,j] - k_means_cluster_centers[k_means_labels[i],j])**2
        if SSE_daily[i] < SSE_closest_day[k_means_labels[i]]: # calc closest day
            cluster_closest_day[k_means_labels[i]] = i
            SSE_closest_day[k_means_labels[i]] = SSE_daily[i]
    weights = weights/k_means_labels.size # calc weights
    # sort in descending order
    ind_w = np.argsort(weights)[::-1] # ::-1 reverse order - descending
    weights = np.sort(weights)[::-1]
    k_means_cluster_centers = k_means_cluster_centers[ind_w]
    cluster_closest_day = cluster_closest_day[ind_w]
    for i in range(k_means_labels.size):
        k_means_labels[i] = np.where(ind_w == k_means_labels[i])[0][0]
    return {'centers':k_means_cluster_centers, 'weights':weights ,'SSE':SSE, 'labels':k_means_labels, 'closest_day': cluster_closest_day }


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



    # input : el_price_resh - array of yearly electricity prices
    #         cluster_centers - day number of cluster center
def plot_clusters(cluster_centers,weights,n_clusters,descript, el_resh, closest_days=np.zeros(1), showfigs = True ):
    f = plt.figure()
    for i in range(n_clusters):
        plt.plot(np.transpose(cluster_centers)[:,i],label='wt='+str(round(weights[i],3)))
        if np.count_nonzero(closest_days):
            plt.plot(el_resh[closest_days[i],:],color= '0.75' , linestyle='--')
            # plot real closest day
    plt.title(descript+': k='+str(n_clusters))
    plt.legend( loc='upper left' )
    axes = plt.gca()
    #axes.set_ylim([0,100])
    if showfigs:
        f.show()
    f.savefig("/data/cees/hteich/clustering/outfiles/save_clusters/clust"+str(n_clusters)+"_"+str(descript)+".png")
    f.savefig("/data/cees/hteich/clustering/outfiles/save_clusters/clust"+str(n_clusters)+"_"+str(descript)+".eps")

def run_hierClust(el_resh,n_clusters):   # el_resh: d,24
    hierClust = AgglomerativeClustering(n_clusters=n_clusters)
    hierClust.fit(el_resh)
    hier_labels = hierClust.labels_
    # make clusters for each label (use kmeans k=1 (average))
    clusters = np.zeros((n_clusters,el_resh.shape[1]))
    n_per_cl = np.zeros(n_clusters)
    for i in range(hier_labels.size):
        clusters[hier_labels[i],:] += el_resh[i,:]
        n_per_cl[hier_labels[i]] += 1    
    for i in range(n_clusters):
        clusters[i] = clusters[i]/n_per_cl[i]

    weights = np.zeros(n_clusters)
    SSE =0
    SSE_daily = np.zeros(hier_labels.size)
    cluster_closest_day = np.zeros(n_clusters) # day number of closest day
    SSE_closest_day = np.ones(n_clusters)*1e25 # np.zeros(n_clusters)
    for i in range(hier_labels.size):
        weights[hier_labels[i]] += 1
        for j in range(el_resh.shape[1]):
            SSE_daily[i] += (el_resh[i,j] - clusters[hier_labels[i],j])**2
            SSE += (el_resh[i,j] - clusters[hier_labels[i],j])**2
        if SSE_daily[i] < SSE_closest_day[hier_labels[i]]: # calc closest day
            cluster_closest_day[hier_labels[i]] = i
            SSE_closest_day[hier_labels[i]] = SSE_daily[i]
    weights = weights/hier_labels.size # calc weights
    # sort in descending order
    ind_w = np.argsort(weights)[::-1] # ::-1 reverse order - descending
    weights = np.sort(weights)[::-1]
    hier_cluster_centers = clusters[ind_w]
    cluster_closest_day = cluster_closest_day[ind_w]

    return {'centers':hier_cluster_centers,'weights':weights,'SSE':SSE, 'labels':hier_labels, 'closest_day': cluster_closest_day}


def run_hierClust_complete(el_resh,n_clusters):   # el_resh: d,24
    hierClust = AgglomerativeClustering(n_clusters=n_clusters,linkage='complete')
    hierClust.fit(el_resh)
    hier_labels = hierClust.labels_
    # make clusters for each label (use kmeans k=1 (average))
    clusters = np.zeros((n_clusters,el_resh.shape[1]))
    n_per_cl = np.zeros(n_clusters)
    SSE =0
    for i in range(hier_labels.size):
        clusters[hier_labels[i],:] += el_resh[i,:]
        n_per_cl[hier_labels[i]] += 1
    for i in range(n_clusters):
        clusters[i] = clusters[i]/n_per_cl[i]
    for i in range(hier_labels.size):
        for j in range(el_resh.shape[1]):
            SSE += (el_resh[i,j] - clusters[hier_labels[i],j])**2
    weights = n_per_cl/hier_labels.size
    return {'centers':clusters,'weights':weights,'SSE':SSE, 'labels':hier_labels}


def run_hierClust_average(el_resh,n_clusters):   # el_resh: d,24
    hierClust = AgglomerativeClustering(n_clusters=n_clusters,linkage='average')
    hierClust.fit(el_resh)
    hier_labels = hierClust.labels_
    # make clusters for each label (use kmeans k=1 (average))
    clusters = np.zeros((n_clusters,el_resh.shape[1]))
    n_per_cl = np.zeros(n_clusters)
    SSE =0
    for i in range(hier_labels.size):
        clusters[hier_labels[i],:] += el_resh[i,:]
        n_per_cl[hier_labels[i]] += 1
    for i in range(n_clusters):
        clusters[i] = clusters[i]/n_per_cl[i]
    for i in range(hier_labels.size):
        for j in range(el_resh.shape[1]):
            SSE += (el_resh[i,j] - clusters[hier_labels[i],j])**2
    weights = n_per_cl/hier_labels.size
    return {'centers':clusters,'weights':weights,'SSE':SSE, 'labels':hier_labels}


def write_clusters_to_txt(cluster_centers, weights, n_clusters,filename_elpr,filename_weight):
    here = os.path.dirname(os.path.realpath(__file__))
    filepath_elpr = os.path.join(here,"representative_days_oxy",filename_elpr)
    filepath_weight = os.path.join(here,"representative_days_oxy",filename_weight)
    with open(filepath_elpr, 'w') as f:
        f.write(str(n_clusters * 24) + '\n')
        for k in range(n_clusters):
            for j in range(24):
                f.write(str(j) + ' ' + str(round(cluster_centers[k][j],10)) + '\n')
    with open(filepath_weight, 'w') as f:
        f.write(str(n_clusters) + '\n')
        for k in range(n_clusters):
            f.write(str(k) + ' ' + str(round(weights[k],10)) + '\n')

def write_clusters_to_txt_battery_opt(cluster_centers, weights, n_clusters,filename_elpr,filename_weight):
    here = os.path.dirname(os.path.realpath(__file__))
    filepath_elpr = os.path.join( here,"outfiles","representative_days",filename_elpr)
    filepath_weight = os.path.join( here,"outfiles","representative_days",filename_weight)
    #filepath_weight = os.path.join(here,"representative_days",filename_weight)
    np.savetxt(filepath_elpr, cluster_centers, fmt='%.7f',delimiter='\t', newline='\n')
    np.savetxt(filepath_weight, weights, fmt='%.7f',delimiter='\n')

# transforms array of day numbers to array of dayXhour prices
def daynum_to_hourlyelprice(sel_days ,el_resh):
    hourly_prices = np.zeros((np.shape(sel_days)[0], np.shape(el_resh)[1]))
    for i in range(np.shape(sel_days)[0]):
        hourly_prices[i,:] = el_resh[sel_days[i],:]
    return hourly_prices

def get_xyz_from_csv_file(csv_file_path):
    '''
    get x, y, z value from csv file
    csv file format: x0,y0,z0
    Used for colormap
    '''
    x = []
    y = []
    z = []
    map_value = {}
    k=0
    i=0
    d=0
    for line in open(csv_file_path):
        if k>0:
            if i==24:
                i=1
                d+=1
            else:
                i+=1
            list = line.split(",")
            temp_x = d+1
            temp_y = i
            temp_z = float(list[0])
            x.append(temp_x)
            y.append(temp_y)
            z.append(temp_z)
            map_value[(temp_x, temp_y)] = temp_z
        k +=1
    return x, y, map_value


def draw_heatmap(x, y, map_value, title=" ", unit=" ", max_col=0 ):
    f = plt.figure()
    plt_x = np.asarray(list(set(x)))
    plt_y = np.asarray(list(set(y)))
    plt_z = np.zeros(shape = (len(plt_x), len(plt_y)))

    for i in range(len(plt_x)):
        for j in range(len(plt_y)):
            if map_value.has_key((plt_x.item(i), plt_y.item(j))):
                plt_z[i][j] = map_value[(plt_x.item(i), plt_y.item(j))]

    z_min = plt_z.min()
    if max_col == 0:
        z_max = plt_z.max()
    else:
        z_max = max_col
    plt_z = np.transpose(plt_z)

    plot_name = title

    max_col = 60 # $/MWh

    color_map = plt.cm.rainbow #plt.cm.rainbow #plt.cm.hot #plt.cm.gist_heat
    plt.clf()
    plt.pcolor(plt_x, plt_y, plt_z, cmap=color_map, vmin=z_min, vmax=z_max)
    plt.axis([plt_x.min(), plt_x.max(), plt_y.min(), plt_y.max()])
    plt.title(plot_name)
    num_days =0
    for i in range(12): # lines between months
        num_days += calendar.monthrange(2015,i+1)[1]
        plt.axvline(num_days, color='k',linestyle='dashed')

    plt.colorbar().set_label(unit, rotation=270)
    ax = plt.gca()
    ax.set_xlabel('day')
    ax.set_ylabel('hour')
    ax.set_aspect(10)
    figure = plt.gcf()
    SIZE = 20
    plt.rc('font', size=SIZE)  # controls default text sizes
    plt.rc('axes', titlesize=SIZE)  # fontsize of the axes title
    plt.rc('axes', labelsize=SIZE)  # fontsize of the x any y labels
    plt.rc('xtick', labelsize=SIZE)  # fontsize of the tick labels
    plt.rc('ytick', labelsize=SIZE)  # fontsize of the tick labels
    plt.rc('legend', fontsize=SIZE)  # legend fontsize
    plt.rc('figure', titlesize=SIZE)  # # size of the figure title
    f.show()
    return figure



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


    plt.close("all")
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
    # Plot 12 month CA electricity price data
    # el_CA_2015_montly = plot_monthly_price(el_CA_2015)

    el_CA_2015_resh = np.reshape(el_CA_2015, (el_CA_2015.size/24, 24))
    el_CA_2015_norm,max_hourly = normalize_by_hour_01(el_CA_2015_resh)
    el_CA_2015_normtot,max_el = normalize_01(el_CA_2015_resh)
    el_CA_2015_norm_meansdv_hourly,mean_hourly,sdv_hourly= normalize_by_hour_meansdv(el_CA_2015_resh)
    el_CA_2015_norm_meansdv,mean_seq,sdv_seq= normalize_by_seq_meansdv(el_CA_2015_resh)
    el_CA_2015_full_meansdv,mean_full,sdv_full= normalize_meansdv(el_CA_2015_resh)
    #pdb.set_trace()

    '''
    # Plot electricity prices in one plot
    #print el_CA_2015_resh
    f = plt.figure()
    for i in range(np.shape(el_CA_2015_resh)[0]):
        plt.plot(el_CA_2015_resh[i,:],alpha=0.3)
    plt.title('Hourly Wholesale Electricity Prices 2015 (CA)')
    #plt.legend( loc='upper left' )
    axes = plt.gca()
    axes.set_xlabel('hour')
    axes.set_ylabel('$/MWh')
    axes.set_ylim([0,100])
    axes.set_xlim([0,23])
    f.show()
    '''







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
        if plots:
            plot_clusters(np.multiply(res['centers'],np.transpose(sdv_hourly))+np.dot(np.identity(np.shape(el_CA_2015_resh)[1]),np.transpose(mean_hourly)),res['weights'],k,region + ' k-shape', el_CA_2015_resh, res['closest_day'], showfigs = showfigs)
        #SSE_kshape[i-1] = res['SSE']
        #cluster_centers_kshape.append(np.multiply(res['centers'],np.transpose(sdv_hourly))+np.dot(np.identity(np.shape(el_CA_2015_resh)[1]),np.transpose(mean_hourly)))
        #labels_kshape.append(res['labels'])
        #wt_kshape.append(res['weights'])
        #cluster_closest_day_kshape.append(res['closest_day'])
        #save centroid 
        filename_ep = reg_str + 'Elec_Price_kmeans_kshape_cluster_' + str(k) + '.txt'
        filename_wt = reg_str + 'Weights_kmeans_kshape_cluster_' + str(k) + '.txt'
        #write_clusters_to_txt_battery_opt(cluster_centers_kshape[i-1],wt_kshape[i-1], k,filename_ep,filename_wt)
        #save closest 
        filename_ep = reg_str + 'Elec_Price_kmeans_kshape_closest_' + str(k) + '.txt'
        filename_wt = reg_str + 'Weights_kmeans_kshape_closest_' + str(k) + '.txt'
        #write_clusters_to_txt_battery_opt(daynum_to_hourlyelprice(cluster_closest_day_kshape[i-1], el_CA_2015_resh),wt_kshape[i-1], k,filename_ep,filename_wt)
    # \todo: Make class out of this - nice plotting of cluster and representation
    
    # time print
    toc_end = time()
    sys.stdout.write("total kshape clustering took: " + str(toc_end - tic_begin) + " s  \n" ) # on cluster, print seems to be omitted in out
    


    # Plot generation Presentation
    if plots:
        k=5
        color_ar = ['b', 'g', 'r','m','c']
        matplotlib.rcParams.update({'font.size': 16})
        f = plt.figure()
        for i in range(k):
            plt.plot(np.transpose(cluster_centers_kshape[k-1])[:,i],label='wt='+str(round((wt_kshape[k])[i],3)), color = color_ar[i])
        plt.title(region + ': ' + 'Hourly electricity price')
        #plt.title('kmeans: k='+str(k))
        plt.legend( loc='upper left',fontsize=12)
        axes = plt.gca()
        axes.set_xlabel('hour')
        axes.set_ylabel('$/MWh')
        axes.set_ylim([0,100])
        axes.set_xlim([0,23])
        if showfigs:
            f.show()

            # Plot electricity prices in one plot
        #print el_CA_2015_resh
        #print np.arange(1,24)
        f = plt.figure()
        for i in range(np.shape(el_CA_2015_resh)[0]):
            plt.plot(el_CA_2015_resh[i,:],alpha=0.4,color = color_ar[(labels_kshape[k-1])[i]])
        #plt.title('Hourly Wholesale Electricity Prices 2015 (CA)')
        #plt.legend( loc='upper left' )
        axes = plt.gca()
        axes.set_xlabel('hour')
        axes.set_ylabel('$/MWh')
        axes.set_ylim([0,100])
        axes.set_xlim([0,23])
        if showfigs:
            f.show()



        # \todo: make this a function
        # plot SSE kmeans
        f = plt.figure()
        plt.plot(n_k,SSE_kshape,label='Kmeans')
        plt.ylabel('SSE')
        plt.xlabel('k')
        plt.legend(loc='upper right' )
        plt.title('Sum of Squared Errors')
        axes = plt.gca()
        axes.set_xlim([1,7])
        if showfigs:
            f.show()
    # end plots



    '''
    csv_file_name = "CA_2015_elPriceStanford.csv"
    x, y, map_value = get_xyz_from_csv_file(csv_file_name)
    draw_heatmap(x, y, map_value,title= 'Electricity Prices CA 2015',unit='$/MWh', max_col=60);

    '''
    if showfigs:
        plt.show()



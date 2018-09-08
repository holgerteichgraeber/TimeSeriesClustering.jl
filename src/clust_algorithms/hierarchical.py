# coding: utf-8

import numpy as np
from sklearn.cluster import AgglomerativeClustering


# note that the input of el_resh is reverse of the julia convention
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
    for i in range(hier_labels.size):
        hier_labels[i] = np.where(ind_w == hier_labels[i])[0][0]
    return {'centers':hier_cluster_centers,'weights':weights,'SSE':SSE, 'labels':hier_labels, 'closest_day_ind': cluster_closest_day}

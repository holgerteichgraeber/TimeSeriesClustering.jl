__author__ = 'brandonkelly'

import numpy as np
from numba import jit
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
import time


@jit  # if you don't have number, then comment out this line but this routine will be slow!
def dynamic_time_warping(tseries1, tseries2):
    """
    Compute the dynamic time warping (DTW) distance between two time series. It is assumed that the time series are
    evenly sampled, but they can have different lengths. Numba is used to speed up the computation, so you must have
    Numba installed. Note that the time series can be multivariate.

    :param tseries1: The first time series, a 1-D or 2-D numpy array.
    :param tseries2: The second time series, a 1-D or 2-D numpy array.
    :return: A tuple containing the DTW distance, the DTW matrix, and the path matrix taken by the algorithm.
    """
    ntime1, nfeatures = tseries1.shape
    ntime2 = tseries2.shape[0]
    dtw = np.zeros((ntime1, ntime2), dtype=np.float)  # matrix of coordinate distances
    path = np.zeros((ntime1, ntime2), dtype=np.int)  # path of algorithm

    # initialize the first row and column
    for k in range(nfeatures):
        dtw[0, 0] += (tseries1[0, k] - tseries2[0, k]) ** 2
    path[0, 0] = -1

    for i in range(1, ntime1):
        dist = 0.0
        for k in range(nfeatures):
            dist += (tseries1[i, k] - tseries2[0, k]) ** 2
        dtw[i, 0] = dtw[i-1, 0] + dist
        path[i, 0] = 2

    for j in range(1, ntime2):
        dist = 0.0
        for k in range(nfeatures):
            dist += (tseries1[0, k] - tseries2[j, k]) ** 2
        dtw[0, j] = dtw[0, j-1] + dist
        path[0, j] = 1

    # main loop of the DTW algorithm
    for i in range(1, len(tseries1)):
        for j in range(1, len(tseries2)):
            a = dtw[i-1, j-1]
            b = dtw[i, j-1]
            c = dtw[i-1, j]
            if a < b:
                if a < c:
                    idx = 0  # a is the minimum
                    delta = a
                else:
                    idx = 2  # c is the minimum
                    delta = c
            else:
                if b < c:
                    idx = 1  # b is the minimum
                    delta = b
                else:
                    idx = 2  # c is the minimum
                    delta = c
            # neighbors = np.array([dtw[i-1, j-1], dtw[i, j-1], dtw[i-1, j]])
            # idx = np.argmin(neighbors)
            # delta = neighbors[idx]
            dist = 0.0
            for k in range(nfeatures):
                dist += (tseries1[i, k] - tseries2[j, k]) ** 2
            dtw[i, j] = dist + delta
            path[i, j] = idx

    return dtw[-1, -1], dtw, path


class DBA(object):

    def __init__(self, max_iter, tol=1e-4, verbose=False):
        """
        Constructor for the DBA class. This class computes the dynamic time warping (DTW) barycenter averaging (DBA)
        strategy for averaging a set of time series. The method is described in

        "A global averaging method for dynamic time warping, with applications to clustering." Petitjean, F.,
            Ketterlin, A., & Gancarski, P. 2011, Pattern Recognition, 44, 678-693.

        :param max_iter: The maximum number of iterations for the DBA algorithm.
        :param tol: The tolerance level for the algorithm. The algorithm terminates once the fractional difference in
            the within-group sum of squares between successive iterations is less than tol. The algorithm will also
            terminate if the maximum number of iterations is exceeded, or if the sum of squares increases.
        :param verbose: If true, then provide helpful output.
        """
        self.max_iter = max_iter
        self.tol = tol
        self.average = np.zeros(1)
        self.wgss = 0.0  # the within-group sum of squares, called the inertia in the clustering literature
        self.verbose = verbose

    def compute_average(self, tseries, nstarts=1, initial_value=None, dba_length=None):
        """
        Perform the DBA algorithm to compute the average for a set of time series. The algorithm is a local optimization
        strategy and thus depends on the initial guess for the average. Improved results can be obtained by using
        multiple random initial starts.

        :param tseries: The list of time series, a list of numpy arrays. Can be multivariate time series.
        :param nstarts: The number of random starts to use for the DBA algorithm. The average time series that minimizes
            the within-group sum of squares over the random starts is returned and saved.
        :param initial_value: The initial value for the DBA algorithm, a numpy array. If None, then the initial values
             will be drawn randomly from the set of input time series (recommended). Note that is an initial guess is
             supplied, then the nstarts parameter is ignored.
        :param dba_length: The length of the DBA average time series. If None, this will be set to the length of the
            initial_value array. Otherwise, the initial value array will be linearly interpolated to this length.
        :return: The estimated average of the time series, defined to minimize the within-group sum of squares of the
            input set of time series.
        """
        if initial_value is not None:
            nstarts = 1

        if initial_value is None:
            # initialize the average as a random draw from the set of inputs
            start_idx = np.random.permutation(len(tseries))[:nstarts]

        best_wgss = 1e300
        if self.verbose:
            print 'Doing initialization iteration:'
        for i in range(nstarts):
            print i, '...'
            if initial_value is None:
                iseries = tseries[start_idx[i]]
            else:
                iseries = initial_value
            if dba_length is not None:
                # linearly interpolate initial average value to the requested length
                iseries0 = np.atleast_2d(iseries)
                if iseries0.shape[0] == 1:
                    iseries0 = iseries0.T  # vector, so transpose to shape (ntime, 1)
                nfeatures = iseries0.shape[1]
                iseries = np.zeros((dba_length, nfeatures))
                for k in range(nfeatures):
                    lininterp = interp1d(np.arange(iseries0.shape[0]), iseries0[:, k])
                    iseries[:, k] = lininterp(np.linspace(0.0, iseries0.shape[0]-1.01, num=dba_length))

            self._run_dba(tseries, iseries)

            if self.wgss < best_wgss:
                # found better average, save it
                if self.verbose:
                    print 'New best estimate found for random start', i
                best_wgss = self.wgss
                best_average = self.average

        self.wgss = best_wgss
        self.average = best_average

        return best_average

    def associate_segments(self, tseries):
        """
        Identify the indices of the inputs time series that are associated with each element of the average time series.

        :param tseries: The times series for which the indices associated with the average are desired. A numpy array.
        :return: A list-of-lists containing the indices of the input time series that are associated with the elements
            of the DBA average. Call this assoc_table. Then assoc_table[i] will return a list of the indices of the
            input time series that are associated with the element i of the DBA average (i.e., self.average[i]).
        """
        dtw_dist, dtw, path = dynamic_time_warping(self.average, tseries)

        # table telling us which elements of the time series are identified with a specific element of the DBA average
        assoc_table = []
        for i in range(self.average.shape[0]):
            assoc_table.append([])

        i = self.average.shape[0] - 1
        j = tseries.shape[0] - 1

        while i >= 0 and j >= 0:
            assoc_table[i].append(j)
            if path[i, j] == 0:
                i -= 1
                j -= 1
            elif path[i, j] == 1:
                j -= 1
            elif path[i, j] == 2:
                i -= 1
            else:
                # should not happen, but just in case make sure we bail once path[i, j] = -1
                break

        return assoc_table

    def _run_dba(self, tseries, initial_value):
        """ Perform the DBA algorithm. """
        nseries = len(tseries)

        self.average = initial_value

        # first iteration: get initial within-group sum of squares
        if self.verbose:
            print 'Doing iteration'
            print ' ', '0', '...'
        wgss = self._dba_iteration(tseries)

        # main DBA loop
        for i in range(1, self.max_iter):
            if self.verbose:
                print ' ', i, '...', 'WGSS:', wgss
            wgss_old = wgss
            # WGSS is actually from previous iteration, but don't compute again because it is expensive
            wgss = self._dba_iteration(tseries)
            if wgss > wgss_old:
                # sum of squares should be non-increasing
                print 'Warning! Within-group sum of squares increased at iteration', i, 'terminating algorithm.'
                break
            elif np.abs(wgss - wgss_old) / wgss_old < self.tol:
                # convergence
                break

        # compute final within-group sum of squares
        wgss = 0.0
        for k in range(nseries):
            wgss += dynamic_time_warping(tseries[k], self.average)[0]
        self.wgss = wgss

    def _dba_iteration(self, tseries):
        """ Perform a single iteration of the DBA algorithm. """
        ntime = self.average.shape[0]

        # table telling us which elements of the time series are identified with a specific element of the DBA average
        assoc_table = []
        for i in range(ntime):
            assoc_table.append([])

        wgss = 0.0  # within group sum of squares from previous iteration, compute here so we don't have to repeat
        for series in tseries:
            if self.average.shape[1] == 1:
                series = series[:, np.newaxis]
            dtw_dist, dtw, path = dynamic_time_warping(self.average, series)
            wgss += dtw_dist
            i = ntime - 1
            j = series.shape[0] - 1
            while i >= 0 and j >= 0:
                assoc_table[i].append(series[j])
                if path[i, j] == 0:
                    i -= 1
                    j -= 1
                elif path[i, j] == 1:
                    j -= 1
                elif path[i, j] == 2:
                    i -= 1
                else:
                    # should not happen, but just in case make sure we bail once path[i, j] = -1
                    break

        # update the average
        for i, cell in enumerate(assoc_table):
            cell_array = np.array(cell)
            self.average[i] = cell_array.mean(axis=0)

        return wgss


if __name__ == "__main__":
    # run on some test data
    nseries = 40
    ntime0 = 1000
    phase1 = 0.1 + 0.2 * np.random.uniform(0.0, 1.0, nseries) - 0.1
    period1 = np.pi / 4.0 + np.pi / 100.0 * np.random.standard_normal(nseries)

    phase2 = np.pi / 2 + 0.2 * np.random.uniform(0.0, 1.0, nseries) - 0.1
    period2 = np.pi / 2.0 + np.pi / 100.0 * np.random.standard_normal(nseries)

    noise_amplitude = 0.0

    t_list = []
    ts_list = []
    for i in range(nseries):
        ntime = np.random.random_integers(ntime0 * 0.9, ntime0 * 1.1)
        t = np.linspace(0.0, 10.0, ntime)
        t_list.append(t)
        tseries = np.zeros((ntime, 2))
        tseries[:, 0] = np.sin(t / period1[i] + phase1[i]) + noise_amplitude * np.random.standard_normal(ntime)
        tseries[:, 1] = np.sin(t / period2[i] + phase2[i]) + noise_amplitude * np.random.standard_normal(ntime)
        ts_list.append(tseries)

    niter = 30
    dba = DBA(niter, verbose=True, tol=1e-4)
    t1 = time.clock()
    dba_avg = dba.compute_average(ts_list, nstarts=5, dba_length=10)
    t2 = time.clock()

    print 'DBA algorithm took', t2 - t1, 'seconds.'

    plt.subplot(221)
    for i in range(nseries):
        plt.plot(t_list[i], ts_list[i][:, 0], '.', ms=2)
        t = np.linspace(0.0, 10.0, len(dba_avg))
    plt.plot(t, dba_avg[:, 0], 'ko')
    plt.subplot(222)
    for i in range(nseries):
        plt.plot(t_list[i], ts_list[i][:, 1], '.', ms=2)
        t = np.linspace(0.0, 10.0, len(dba_avg))
    plt.plot(t, dba_avg[:, 1], 'ko')
    plt.subplot(223)
    for ts in ts_list:
        plt.plot(ts[:, 0], ts[:, 1], '.', ms=2)
    plt.plot(dba_avg[:, 0], dba_avg[:, 1], 'ko')
    plt.show()
    plt.close()

    # find the segments of the first time series identified with each element of the average
    assoc = dba.associate_segments(ts_list[0])
    plt.subplot(221)
    t = t_list[0]
    ts = ts_list[0]
    for i, a in enumerate(assoc):
        plt.plot(t[a], ts[a, 0], '.', label=str(i))
        plt.plot(np.median(t[a]), dba_avg[i, 0], 'ko')
    plt.subplot(222)
    for i, a in enumerate(assoc):
        plt.plot(t[a], ts[a, 1], '.', label=str(i))
        plt.plot(np.median(t[a]), dba_avg[i, 1], 'ko')
    plt.subplot(223)
    for i, a in enumerate(assoc):
        plt.plot(ts[a, 0], ts[a, 1], '.', label=str(i))
        plt.plot(dba_avg[i, 0], dba_avg[i, 1], 'ko')
    plt.show()
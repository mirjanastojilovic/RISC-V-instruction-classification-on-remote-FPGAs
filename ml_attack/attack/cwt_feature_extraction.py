# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# Jinwei Yao  Summer@EPFL Zhejiang University
import numpy
from matplotlib import pyplot

import pycwt as wavelet
from pycwt.helpers import find
import random

def CTW_extract_feature(X):
    t0 = 0
    dt = 1 

    # We also create a time array 
    # N = dat.size
    N = X.size
    # print(N)
    t = numpy.arange(0, N) * dt + t0
    # print(t)
    # We write the following code to detrend and normalize the input data by its
    # standard deviation. Sometimes detrending is not necessary and simply
    # removing the mean value is good enough. However, if your dataset has a well
    # defined trend, such as the Mauna Loa CO\ :sub:`2` dataset available in the
    # above mentioned website, it is strongly advised to perform detrending.
    # Here, we fit a one-degree polynomial function and then subtract it from the
    # original data.
    p = numpy.polyfit(t - t0, X, 1)
    dat_notrend = X - numpy.polyval(p, t - t0)
    std = dat_notrend.std()  # Standard deviation
    var = std ** 2  # Variance
    dat_norm = dat_notrend / std  # Normalized dataset
    # print(dat_norm)
    
    # The next step is to define some parameters of our wavelet analysis. We
    # select the mother wavelet, in this case the Morlet wavelet with
    # :math:`\omega_0=6`.
    mother = wavelet.Morlet(6)
    s0 = 2*dt # Starting scale, in this case 2*dt
    dj = 1 / 12  # Twelve sub-octaves per octaves
    J = 4 / dj  # Seven powers of two with dj sub-octaves
    # J = 8 / dj  # Seven powers of two with dj sub-octaves
    alpha, _, _ = wavelet.ar1(X)  # Lag-1 autocorrelation for red noise

    # The following routines perform the wavelet transform and inverse wavelet
    # transform using the parameters defined above. Since we have normalized our
    # input time-series, we multiply the inverse transform by the standard
    # deviation.

    # signal : numpy.ndarray, list
    #     Input signal array.
    # dt : float
    #     Sampling interval.
    # dj : float, optional
    #     Spacing between discrete scales. Default value is 1/12.
    #     Smaller values will result in better scale resolution, but
    #     slower calculation and plot.
    # s0 : float, optional
    #     Smallest scale of the wavelet. Default value is 2*dt.
    # J : float, optional
    #     Number of scales less one. Scales range from s0 up to
    #     s0 * 2**(J * dj), which gives a total of (J + 1) scales.
    #     Default is J = (log2(N * dt / so)) / dj.
    # wavelet : instance of Wavelet class, or string
    #     Mother wavelet class. Default is Morlet wavelet.
    # freqs : numpy.ndarray, optional
    #     Custom frequencies to use instead of the ones corresponding
    #     to the scales described above. Corresponding scales are
    #     calculated using the wavelet Fourier wavelength.

    # Returns
    # -------
    # W : numpy.ndarray
    #     Wavelet transform according to the selected mother wavelet.
    #     Has (J+1) x N dimensions.
    # sj : numpy.ndarray
    #     Vector of scale indices given by sj = s0 * 2**(j * dj),
    #     j={0, 1, ..., J}.
    # freqs : array like
    #     Vector of Fourier frequencies (in 1 / time units) that
    #     corresponds to the wavelet scales.
    # coi : numpy.ndarray
    #     Returns the cone of influence, which is a vector of N
    #     points containing the maximum Fourier period of useful
    #     information at that particular time. Periods greater than
    #     those are subject to edge effects.
    # fft : numpy.ndarray
    #     Normalized fast Fourier transform of the input signal.
    # fftfreqs : numpy.ndarray
    #     Fourier frequencies (in 1/time units) for the calculated
    #     FFT spectrum.

    # Example
    # -------
    # >> mother = wavelet.Morlet(6.)
    # >> wave, scales, freqs, coi, fft, fftfreqs = wavelet.cwt(signal,
    #        0.25, 0.25, 0.5, 28, mother)

    
    wave, scales, freqs, coi, fft, fftfreqs = wavelet.cwt(dat_norm, dt, dj, s0, J,
                                                mother)
    # wave, scales, freqs, coi, fft, fftfreqs = wavelet.cwt(dat_norm, dt)
    # print(wave)
    return wave
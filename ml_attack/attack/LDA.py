# Instruction-Level Power Side-Channel Leakage Evaluation of Soft-Core CPUs on Shared FPGAs
# Copyright 2023, School of Computer and Communication Sciences, EPFL.
#
# All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE.md file.

# JINWEI YAO SUMMER@EPFL 21
#REF:https://scikit-learn.org/stable/modules/generated/sklearn.decomposition.LatentDirichletAllocation.html
# Linear Discriminant Analysis

# A classifier with a linear decision boundary, generated by fitting class conditional densities to the data and using Bayes’ rule.

# The model fits a Gaussian density to each class, assuming that all classes share the same covariance matrix.

# The fitted model can also be used to reduce the dimensionality of the input by projecting it to the most discriminative directions, using the transform method.

from sklearn.discriminant_analysis import LinearDiscriminantAnalysis as LDA

def myLDA(X_profiling, Y_profiling, new_feature_number):
    lda=LDA(n_components=new_feature_number)
    # Fit to data, then transform it.
# Fits transformer to X and y with optional parameters fit_params and returns a transformed version of X.
    X_profiling=lda.fit_transform(X_profiling, Y_profiling)
    # print("LDA done!\n")
    return X_profiling
    
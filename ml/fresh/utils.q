// fresh/utils.q - Utility functions
// Copyright (c) 2021 Kx Systems Inc
//
// Unitily functions used in the implimentation of FRESH

\d .ml

// Python imports
sci_ver  :"F"$"." vs cstring .p.import[`scipy][`:__version__]`
sci_break:((sci_ver[0]=1)&sci_ver[1]>=5)|sci_ver[0]>1
numpy    :.p.import`numpy
pyStats  :.p.import`scipy.stats
signal   :.p.import`scipy.signal
stattools:.p.import`statsmodels.tsa.stattools
stats_ver:"F"$"." vs cstring .p.import[`statsmodels][`:__version__]`
stats_break:((stats_ver[0]=0)&stats_ver[1]>=12)|stats_ver[0]>0

// @private
// @kind function 
// @category freshPythonUtility
// @desc Compute the one-dimensional
//   discrete Fourier Transform for real input
fresh.i.rfft:numpy`:fft.rfft

// @private
// @kind function 
// @category freshPythonUtility
// @desc Return the real part of the complex argument
fresh.i.real:numpy`:real

// @private
// @kind function 
// @category freshPythonUtility
// @desc Return the angle of the complex argument
fresh.i.angle:numpy`:angle

// @private
// @kind function 
// @category freshPythonUtility
// @desc Return the imaginary part of the complex argument
fresh.i.imag:numpy`:imag

// @private
// @kind function 
// @category freshPythonUtility
// @desc Calculate the absolute value element-wise
fresh.i.abso:numpy`:abs

// @private
// @kind function 
// @category freshPythonUtility
// @desc Kolmogorov-Smirnov two-sided test statistic distribution
fresh.i.ksDistrib:pyStats[$[sci_break;`:kstwo.sf;`:kstwobign.sf];<]

// @private
// @kind function 
// @category freshPythonUtility
// @desc Calculate Kendall’s tau, a correlation measure for
//   ordinal data
fresh.i.kendallTau:pyStats`:kendalltau

// @private
// @kind function 
// @category freshPythonUtility
// @desc Perform a Fisher exact test on a 2x2 contingency table
fresh.i.fisherExact:pyStats`:fisher_exact

// @private
// @kind function 
// @category freshPythonUtility
// @desc Estimate power spectral density using Welch’s method
fresh.i.welch:signal`:welch

// @private
// @kind function 
// @category freshPythonUtility
// @desc Find peaks in a 1-D array with wavelet transformation
fresh.i.findPeak:signal`:find_peaks_cwt

// @private
// @kind function 
// @category freshPythonUtility
// @desc Calculate the autocorrelation function
fresh.i.acf:stattools`:acf

// @private
// @kind function 
// @category freshPythonUtility
// @desc Partial autocorrelation estimate
fresh.i.pacf:stattools`:pacf

// @private
// @kind function 
// @category freshPythonUtility
// @desc Augmented Dickey-Fuller unit root test
fresh.i.adFuller:stattools`:adfuller

// Python features
fresh.i.pyFeat:`aggAutoCorr`augFuller`fftAggReg`fftCoeff`numCwtPeaks,
  `partAutoCorrelation`spktWelch

// Extract utilities

// @private
// @kind function
// @category freshUtility
// @desc Create a mapping between the functions and columns on which
//   they are to be applied
// @param map {symbol[][]} Two element list where first element is the
//   columns to which functions are to be applied and the second element is
//   the name of the function in the .ml.fresh.feat namespace to be applied
// @return {symbol[]} A mapping of the functions to be applied to each column
fresh.i.colMap:{[map]
  updFunc:flip (` sv'`.ml.fresh.feat,'map[;1];map[;0]);
  updFunc,'last@''2_'map
  }

// @private
// @kind function
// @category freshUtility
// @desc Returns features given data and function params with error handling
// @param data {table} Data on which to generate features
// @param funcs {dictionary} Function names with functions to execute
// @param idCol {list} Columns to index
// @return {table} Unexpanded list of features
fresh.i.protect:{[data;funcs;idCol]
  {@[
    {?[x;();z!z;enlist[y 0]!enlist 1_y]}[x;;z];
    y;
    {-1"Error generating function : ",string[x 0]," with error ",y;()}[y]
  ]}[data;;idCol]'[key[funcs],'value funcs]};

// @private
// @kind function 
// @category freshUtility
// @desc Returns the length of each sequence
// @param condition {boolean} Executed condition, e.g. data>avg data
// @return {long[]} Sequence length based on condition
fresh.i.getLenSeqWhere:{[condition]
  idx:where differ condition;
  (1_deltas idx,count condition)where condition idx
  }

// @private
// @kind function 
// @category freshUtility
// @desc Find peaks within the data
// @param data {number[]} Numerical data points
// @param support {long} Support of the peak
// @param idx {long} Current index
// @return {boolean[]} 1 where peak exists
fresh.i.peakFind:{[data;support;idx]
  neg[support]_support _min data>/:xprev\:[-1 1*idx]data
  }

// @private
// @kind function 
// @category freshUtility
// @desc Expand results produced by FRESH
// @param results {table} Table of resulting features
// @param column {symbol} Column of interest
// @return {table} Expanded results table
fresh.i.expandResults:{[results;column]
  t:(`$"_"sv'string column,'cols t)xcol t:results column;
  ![results;();0b;enlist column],'t
  }

// Select utilities

// @private
// @kind function
// @category freshUtility
// @desc Apply python function for Kendall’s tau
// @param target {number[]} Target vector
// @param feature {number[]} Feature table column
// @return {float} Kendall’s tau - Close to 1 shows strong agreement, close to
//   -1 shows strong disagreement
fresh.i.kTau:{[target;feature]
  fresh.i.kendallTau[target;feature][`:pvalue]`
  }

// @private
// @kind function
// @category freshUtility
// @desc Perform a Fisher exact test
// @param target {number[]} Target vector
// @param feature {number[]} Feature table column
// @return {float} Results of Fisher exact test
fresh.i.fisher:{[target;feature]
  g:group@'target value group feature;
  fresh.i.fisherExact[count@''@\:[g]distinct target][`:pvalue]`
  }

// @private
// @kind function
// @category freshUtility
// @desc Calculate the Kolmogorov-Smirnov two-sided test statistic
//   distribution
// @param feature {number[]} Feature table column
// @param target {number[]} Target vector
// @return {float} Kolmogorov-Smirnov two-sided test statistic distribution
fresh.i.ks:{[feature;target]
  d:asc each target group feature;
  n:count each d;
  k:max abs(-). value(1+d bin\:raze d)%n;
  en:prd[n]%sum n;
  fresh.i.ksDistrib .$[sci_break;(k;ceiling en);enlist k*sqrt en]
  }

// @private
// @kind function
// @category freshUtility
// @desc Pass data correctly to .ml.fresh.i.ks allowing for projection
//   in main function
// @param target {number[]} Target vector
// @param feature {number[]} Feature table column
// @return {float} Kolmogorov-Smirnov two-sided test statistic distribution
fresh.i.ksYX:{[target;feature]
  fresh.i.ks[feature;target]
  }

// @private
// @kind function
// @category freshUtility
// @desc Generate features for fresh feature creation 
// @param features {symbol|symbol[]|null} Features to remove
// @return {table} Updated table of features
fresh.util.featureList:{[features]
  noHP:`aggLinTrend`autoCorr`binnedEntropy`c3`cidCe`eRatioByChunk`fftCoeff,
    `indexMassQuantile`largestDev`numCrossing`numCwtPeaks`numPeaks,
    `partAutoCorrelation`quantile`ratioBeyondRSigma`spktWelch,
    `symmetricLooking`treverseAsymStat`valCount`rangeCount`changeQuant;
  noPY:`aggAutoCorr`fftAggreg`fftCoeff`numCwtPeaks`partAutoCorrelation,
    `spktWelch;
  noClass:`aggLinTrend`aggFuller`c3`cidCe`linTrend`mean2DerCentral,
    `perRecurToAllData`perRecurToAllVal`symmetricLooking`treverseAsymStat;
  $[(features~(::))|features~`regression;
     :.ml.fresh.params;
    features~`noHyperparameters;
     :update valid:0b from .ml.fresh.params where f in noHP;
    features~`noPython;
     :update valid:0b from .ml.fresh.params where f in noPY;
    features~`classification;
     :update valid:0b from .ml.fresh.params where f in noClass;
    (11h~abs type[features])& all ((),features) in\: key[.ml.fresh.params]`f;
     :update valid:0b from .ml.fresh.params where not f in ((),features);
     '"Params not recognized"
    ];
  };

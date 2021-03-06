source("./jd_init.R")
source("./jd_ts.R")
source("./jd_calendars.R")
source("./jd_regression.R")
source("./jd_sa.R")
source("./jd_sa_advanced.R")
source("./jd_rslts.R")
source("./jd_spec.R")
source("./jd_cholette.R")

# usual R time series
data<-read.table("../Data/xm.txt")
s<-ts(data[,1], start=c(1995,1), frequency=12)

# results will be retrieved from the output of the sa routines
# through the proc_xxx functions

# executes TramoSeats (RSA4 by default)
tramoseats_rslts=sa_tramoseats(s)
# executes X11/X13 (pre-defined specifications)
x11_rslts<-sa_x13(s, "X11")
x13_rslts<-sa_x13(s, "RSA5c")

# advanced processing
# create a spec file that will modify an existing specification
spec<-spec_create()
spec_bool(spec, "tramo.automdl.enabled", FALSE)
spec_fixedparams(spec, "tramo.arima.btheta", -.8)
spec_nparams(spec, "tramo.arima.phi", 2)
spec_bool(spec, "tramo.regression.calendar.td.auto", TRUE)
spec_strs(spec, "tramo.regression.outliers", c("LS.2005-12-01.f"))

# execute TramoSeats on the series s, using the "RSA4" specification modified by the given spec details (see above)
tramoseats_rslts2=sa_tramoseats(s,"RSA4",spec)
proc_desc(tramoseats_rslts2, "regression.description")

# retrieve the seasonally adjusted series
sa0<-proc_ts(x13_rslts, "sa")
sa1<-proc_ts(tramoseats_rslts, "sa")
#trend
t0<-proc_ts(x13_rslts, "t")
t1<-proc_ts(tramoseats_rslts, "t")
#d7 table
d7<-proc_ts(x13_rslts, "decomposition.d-tables.d7")
#series corrected for calendar effects
ycal0<-proc_ts(x13_rslts, "ycal")
ycal1<-proc_ts(tramoseats_rslts, "ycal")

# Usual R commands
ts.union(s,ycal0,sa0,t0)
ts.union(s,ycal1,sa1,t1)
ts.plot(s,sa0, t0, col=c("black", "blue", "red"))

#RegArima model
# regression variables
proc_desc(x13_rslts, "regression.description")

#regression coefficients. Value/standard deviation. See description for their meaning
proc_parameters(x13_rslts, "regression.coefficients")

#test Value/PValue
proc_test(x13_rslts, "residuals.lb")
proc_test(x13_rslts, "residuals.skewness")

#BIC
proc_numeric(tramoseats_rslts, "likelihood.bicc")
proc_numeric(tramoseats_rslts2, "likelihood.bicc")


#arima models
proc_str(x13_rslts, "arima")
proc_str(tramoseats_rslts, "arima")
proc_str(tramoseats_rslts2, "arima")

sy<-ts_aggregate(s, 1)
sy

sa0c<-jd_cholette(sa0, sy, 1, 1)
sa0cc<-jd_cholette(sa0, sy, 1, 0)
sa0ccc<-jd_denton(sa0, sy)
sa0cccc<-jd_denton(sa0, sy, mul = FALSE, d=2)
ts.union(sa0, sa0c, sa0cc, sa0ccc, sa0cccc)

# regarima models
tsmodel<-(proc_regarima(tramoseats_rslts))
x13model<-(proc_regarima(x13_rslts))
           
# forecasts tests
# The returned values are: mean, expected mean, mean squared error, pvalue of mean test (with distribution)
# options: out-of-sample/in-sample, number of forecasts  
proc_forecasting(tsmodel)
proc_forecasting(x13model)

proc_forecasting(tsmodel, outofsample = FALSE)
proc_forecasting(x13model, outofsample = FALSE)

proc_forecasting(tsmodel, nfcasts = 36)
proc_forecasting(x13model, nfcasts = 36)

proc_forecasting(tsmodel, FALSE, 36)
proc_forecasting(x13model, FALSE, 36)

# Retrieve the outliers 
# if all, estimated and pre-specifed outliers are returned
# if fixed, all outliers are fixed (otherwise, only the pre-specified) 
# Default: all=TRUE, fixed=TRUE
proc_outliers(preprocessing = proc_preprocessing(tramoseats_rslts2))
proc_outliers(preprocessing = proc_preprocessing(tramoseats_rslts2), fixed=FALSE)
proc_outliers(preprocessing = proc_preprocessing(tramoseats_rslts2), all=FALSE)
proc_outliers(preprocessing = proc_preprocessing(tramoseats_rslts2), all=FALSE, fixed = FALSE)


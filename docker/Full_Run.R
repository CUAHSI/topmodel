# Set the working directory to the current directory
setwd(getwd())
print(paste("Current working directory:", getwd()))

# Load necessary libraries
library(topmodel)
library(Hmisc)


############ PART 0: Topographical Analysis ##############

# Load and prepare the topographic data (DEM) 
# Use the DEM from the Huagrahuma catchment as an example
data(huagrahuma.dem)

# Calculate the topographic wetness index (TWI), with a resolution in meters.
# First, fill pits in the DEM using the sinkfill() function.
DEM = sinkfill(huagrahuma.dem, res = 25, degree = 0.1)   
topindex = topidx(DEM, resolution = 25) 

# The TWI values (atb) need to be classified into hydrological response units.
# TOPMODEL groups similar areas into these units for semi-distributed modeling.
topidx = make.classes(topindex$atb, 16) 

# Generate the delay function of the catchments, which requires cumulative fractions.
n = 5 # Number of classes; more classes yield a smoother histogram
delay = flowlength(huagrahuma.dem) * 25     # TODO: Consider adding outlet coordinates
delay = make.classes(delay, n)
delay = delay[n:1, ]
delay[, 2] = c(0, cumsum(delay[1:(n-1), 2]))


############ PART 2: Running the rainfall-runoff model #########

# Load the example dataset from the Huagrahuma catchment
# and attach it to the search path for easier variable access
data(huagrahuma)
attach(huagrahuma)

# Initial exploration of the dataset
#str(huagrahuma)
#print(topidx)
#print(parameters)
#print(rain)

# Plot the rainfall data to visualize
plot(rain, type = "h", main = "Rainfall Data")

# Run TOPMODEL and visualize the simulated streamflow (Qsim)
Qsim = topmodel(parameters, topidx, delay, rain, ETp)
plot(Qsim, type = "l", col = "red", main = "Simulated Streamflow")
points(Qobs)

# Evaluate the model performance using Nash-Sutcliffe efficiency
nse_value = NSeff(Qobs, Qsim)
print(paste("Nash-Sutcliffe Efficiency:", nse_value))


############ PART 3: Sensitivity Analysis ######################

# Start by varying a single parameter ('m') and analyze its effect on output
parameters["m"] = runif(1, min = 0, max = 0.1)
print(paste("Random parameter 'm':", parameters["m"]))

# Re-run model and evaluate performance
Qsim <- topmodel(parameters, topidx, delay, rain, ETp)
nse_value <- NSeff(Qobs, Qsim)
print(paste("Nash-Sutcliffe Efficiency after variation:", nse_value))

# Plot to verify the simulation result
plot(Qsim, type = "l", col = "red", main = "Simulation After Parameter Variation")
points(Qobs)

# Sample all parameters randomly for a comprehensive sensitivity analysis
n = 100
qs0 = runif(n, min = 0.0001, max = 0.00025)
lnTe = runif(n, min = -2, max = 3)
m = runif(n, min = 0, max = 0.1)
Sr0 = runif(n, min = 0, max = 0.2)
Srmax = runif(n, min = 0, max = 0.1)
td = runif(n, min = 0, max = 3)
vch = runif(n, min = 100, max = 2500)
vr = runif(n, min = 100, max = 2500)
k0 = runif(n, min = 0, max = 10)
CD = runif(n, min = 0, max = 5)
dt = 0.25

parameters = cbind(qs0, lnTe, m, Sr0, Srmax, td, vch, vr, k0, CD, dt)

# Run model for multiple parameter sets and calculate Nash-Sutcliffe efficiency
NS = topmodel(parameters, topidx, delay, rain, ETp, Qobs = Qobs)
max_nse = max(NS)
print(paste("Maximum Nash-Sutcliffe Efficiency:", max_nse))

# Plot sensitivity analysis results
plot(lnTe, NS, ylim = c(0, 1), main = "Sensitivity Analysis: lnTe vs NS")


############ PART 4: GLUE uncertainty analysis #################

# Choose a behavioral threshold and remove poor parameter sets
threshold = 0.3
parameters = parameters[NS > threshold, ]
NS = NS[NS > threshold]

# Generate predictions for the behavioral parameter sets
Qsim = topmodel(parameters, topidx, delay, rain, ETp)

# Visualize predictions for the first time step
hist(Qsim[1, ], main = "Predictions at First Time Step")

# Construct weights based on model performance
weights = NS - threshold
weights = weights / sum(weights)

# Calculate prediction boundaries using weighted quantiles
limits = apply(Qsim, 1, "wtd.quantile", weights = weights, probs = c(0.05, 0.95), normwt = TRUE)

# Plot prediction limits and observed data
plot(limits[2, ], type = "l", main = "Prediction Limits vs Observations")
lines(limits[1, ], type = "l")
points(Qobs, col = "red")

# Count observations falling outside prediction limits
outside = (Qobs > limits[2, ]) | (Qobs < limits[1, ])
outside_summary = summary(outside)
print(outside_summary)

# Calculate average width of prediction boundaries relative to mean observations
prediction_width = mean(limits[2, ] - limits[1, ]) / mean(Qobs, na.rm = TRUE)
print(paste("Average Prediction Width:", prediction_width))



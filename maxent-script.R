## RUNNING MAXENT ON R 

# retrieve relevant packages
library(dismo)
library(raster)

# jar should contain the path to the maxent jar file on your system 
jar <- paste(system.file(package="dismo"), "/java/maxent.jar", sep='')
# check if maxent can be run 
if (file.exists(jar) & require(rJava)) {
  print("True")}

# get predictor variables and store as a stack
var1_mean_annual_temp = raster("data/mean_annual_temp.asc")
var2_annual_heat_moisture = raster("data/annual_heat_moisture.asc")
raster_stack <- stack(var1_mean_annual_temp, var2_annual_heat_moisture)

# get occurrence data (presence points)
occ = read.csv("data/eurybia-conspicua-sdm.csv")
# select only the lon and lat columns 
occ = occ[, c("longitude", "latitude")]

# unlike the maxent application, maxent on R does not remove occurrence 
# points that are outside the spatial extent of our raster; 
# we will need to remove them manually
min_lon_ras = extent(var1_mean_annual_temp)[1]
max_lon_ras = extent(var1_mean_annual_temp)[2]
min_lat_ras = extent(var1_mean_annual_temp)[3]
max_lat_ras = extent(var1_mean_annual_temp)[4]
occ = occ[occ$latitude >= min_lat_ras & occ$latitude <= max_lat_ras &
            occ$longitude >= min_lon_ras & occ$longitude <= max_lon_ras, ]

# witholding a 20% sample for testing 
fold = kfold(occ, k=5)
occtest = occ[fold == 1, ]
occtrain = occ[fold != 1, ]

# crop predictor variables, else running maxent will take very long
min_lon_occ = min(occ$longitude)-3
max_lon_occ = max(occ$longitude)+3
min_lat_occ = min(occ$latitude)-3
max_lat_occ = max(occ$latitude)+3
crop_extent <- extent(min_lon_occ, max_lon_occ, min_lat_occ, max_lat_occ)
cropped_raster_stack <- crop(raster_stack, crop_extent)
predictors <- as(cropped_raster_stack, "SpatialGridDataFrame")

# fit model
# there are a variety of arguments you could input here 
# J stands for jackknife, P stands for response curves 
me <- maxent(x=predictors, p=occtrain, args=c("-J","-P"))
me # this opens a html file, similar to the one for the maxent application

# view percent contribution for each variable  
plot(me)
# view response curves
response(me) 


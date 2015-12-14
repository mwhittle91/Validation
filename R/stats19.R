library(sp)
library(rasterVis)
library(tmap)
library(rgeos)

z <- readRDS("data/z.Rds")
al <- raster::shapefile("data/stats19-lds-cyclists.shp")
plot(al)

# Create raster layer for the aggregation of crashes and model output
# convert to projected CRS

al <- spTransform(al, CRS("+init=epsg:27700"))
z <- spTransform(z, CRS("+init=epsg:27700"))
library(raster)
lr <- raster(z, res = 100)

lrp <- rasterize(al, y = lr, field = rep(1, length(lr)), fun = "count")
plot(lrp)
library(ggplot2)
# lrp <- log(lrp)
rasterVis::gplot(lrp) + geom_tile(aes(fill = value))
rasterVis::levelplot(lrp)


# writeRaster(lrp, filename = "data/lrp_stats19_raster.asc")
# 
# save(z, al, lr, lrp, file = "data1.RData")

# load model output
rnet <- readRDS("data/rnet.Rds")
rnet <- spTransform(rnet, CRSobj = CRS("+init=epsg:27700"))
rnet$nsample <- gLength(rnet, byid = T) * rnet$gov_target / 20000
summary(rnet$nsample)

# sample along route network with n proportional to rnet@data$gov_target
i = 2
i <- which(rnet$nsample > 0.5)[1]
rnet_u <- rnet[i,] # create unique segment
rnet_u$nsample
if(rnet_u$nsample > 0.5){
  # generate point sample
  psam <- spsample(x = rnet_u, n = round(rnet_u$nsample), type = "random") 
}
for(i in 1:nrow(rnet)){
  rnet_u <- rnet[i,] # create unique segment
  if(rnet_u$nsample > 0.5){
    # generate point sample
    psam <- sbind(psam, spsample(x = rnet_u, n = round(rnet_u$nsample), type = "random"))
    perc_temp <- i%%round(nrow(rnet)/100)
    if (!is.na(perc_temp) & perc_temp == 0) {
      message(paste0(round(100 * i/nrow(rnet)), " % out of ", 
                     nrow(rnet), " distances calculated"))
    }
  }
}

mrp <- rasterize(psam, y = lr, field = rep(1, length(lr)), fun = "count")
rasterVis::levelplot(lrp)
rasterVis::levelplot(mrp)

png(file = "Maps/lrp.png", width = 800, height = 800)
rasterVis::levelplot(lrp)
dev.off()

png(file = "Maps/mrp.png", width = 800, height = 800)
rasterVis::levelplot(mrp)
dev.off()

par(mfrow = c(1, 1))

df <- data.frame(Stats19 = values(lrp), Model = values(mrp))
plot(df)

ggplot(df, aes(Stats19, Model)) + geom_hex()
cor(df$Stats19, df$Model, use = "complete.obs")

df[is.na(df)] <- 0
sum(df$Stats19 == 0 & df$Model == 0) / nrow(df)
sum(df$Stats19 > 0 & df$Model == 0) / nrow(df)
sum(df$Stats19 == 0 & df$Model > 0) / nrow(df)
sum(df$Stats19 > 0 & df$Model > 0) / nrow(df)

df

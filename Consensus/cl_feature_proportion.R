rm(list=ls())

library(stats)
source("functions_subtyping.R")

plot_feature_proportion <- function(region, cluster_type, flip) {
  
  df_feat <- read.csv(paste0("PPCG.txt"), sep = "\t")
  df_region <- read.csv("PPCG_region.txt", sep = "\t", header=F)
  colnames(df_region) <- c("Sample_ID","Region")
  
  if (region != "") {
    df_region <- df_region[df_region$Region == region,]
    #print(paste0(region,nrow(df_region)))
    df_feat <- df_feat[df_feat$Sample_ID %in% df_region$Sample_ID,]
  }
  
  #print(paste0(region,nrow(df_feat)))
  
  df_clust <- read.csv(paste0(cluster_type,".txt"), sep = "\t")
  
  df_feat <- update_column_names(df_feat)
  
  convert_to_presence <- function(x) {
    med <- median(x)
    y <- ifelse(x > med, 1, 0)
    return(y)
  }
  
  df_samples <- df_feat[1]
  feature_names <- colnames(df_feat[-1])
  
  write.table(feature_names, file = paste0("PPCG_feature_names.txt"), sep="\t",quote=F, row.names = FALSE, col.names = FALSE)
  
  df_converted <- df_feat[-1]
  df_converted[,c("SNVs")] <- convert_to_presence(df_converted[,c("SNVs")])
  df_converted[,c("InDels")] <- convert_to_presence(df_converted[,c("InDels")])                                    
  df_converted[,c("Insertions (InDels)")] <- convert_to_presence(df_converted[,c("Insertions (InDels)")])                        
  df_converted[,c("Deletions (InDels)")] <- convert_to_presence(df_converted[,c("Deletions (InDels)")])                         
  df_converted[,c("SVs")] <- convert_to_presence(df_converted[,c("SVs")])                                        
  df_converted[,c("Inversions (SVs)")] <- convert_to_presence(df_converted[,c("Inversions (SVs)")])                           
  df_converted[,c("Deletions (SVs)")] <- convert_to_presence(df_converted[,c("Deletions (SVs)")])                            
  df_converted[,c("Tandem Duplications (SVs)")] <- convert_to_presence(df_converted[,c("Tandem Duplications (SVs)")])                  
  df_converted[,c("Translocations (SVs)")] <- convert_to_presence(df_converted[,c("Translocations (SVs)")])                       
  df_converted[,c("Ploidy")] <- convert_to_presence(df_converted[,c("Ploidy")])                                     
  df_converted[,c("PGA (clonal)")] <- convert_to_presence(df_converted[,c("PGA (clonal)")])                               
  df_converted[,c("PGA (subclonal)")] <- convert_to_presence(df_converted[,c("PGA (subclonal)")])                         
  df_converted[,c("PGA")] <- convert_to_presence(df_converted[,c("PGA")])                                        
  df_converted[,c("Proportion of CT")] <- convert_to_presence(df_converted[,c("Proportion of CT")])                          
  df_converted[,c("CT count")] <- convert_to_presence(df_converted[,c("CT count")])                                   
  df_converted[,c("Max CT region")] <- convert_to_presence(df_converted[,c("Max CT region")])                              
  df_converted[,c("Kataegis")] <- convert_to_presence(df_converted[,c("Kataegis")])       
  
  df_converted <- cbind(df_samples, df_converted)
  
  df <- merge(df_clust, df_converted, by="Sample_ID")
  
  if (cluster_type =="CA_tm_ppcg1") {
    #tm1 1 + 3
    typeA <- df[df$Cluster == 2,]
    typeB <- df[df$Cluster == 1 | df$Cluster == 3,]  
  } else if (cluster_type =="CA_arbs") {
    #arbs 1 + 3
    typeA <- df[df$Color == 2,]
    typeB <- df[df$Color == 1 | df$Color == 3,]  
  } else if (flip == "flip") {
    typeA <- df[df$Cluster == 2,]
    typeB <- df[df$Cluster == 1,]  
  } else if (flip == "") {
    typeA <- df[df$Cluster == 1,]
    typeB <- df[df$Cluster == 2,]  
  }
 
  #typeB <- df[df$Cluster == 3,]
  
  typeA_count <- as.integer(nrow(typeA))
  typeB_count <- as.integer(nrow(typeB))
  
  df_prop_sum <- data.frame(matrix(vector(),0,6,dimnames=list(c(), c("ID","Feature", "Type", "Prop","PVal", "Sig"))), stringsAsFactors = F)
  df_prop_sumA <- data.frame(matrix(vector(),0,6,dimnames=list(c(), c("ID","Feature", "Type", "Prop","PVal", "Sig"))), stringsAsFactors = F)
  df_prop_sumB <- data.frame(matrix(vector(),0,6,dimnames=list(c(), c("ID","Feature", "Type", "Prop","PVal", "Sig"))), stringsAsFactors = F)
  df_sig <- data.frame(matrix(vector(),0,3,dimnames=list(c(), c("Feature","PVal", "Sig"))), stringsAsFactors = F)
  
  for (i in 1:length(feature_names)) {
    name <- feature_names[i]
    resultsA <- typeA[,c(feature_names[i])]
    resultsB <- typeB[,c(feature_names[i])]
    #print(paste0("a",resultsA))
    #print(paste0("b",resultsB))
    
    typeA_feat_count <- as.integer(sum(resultsA == 1))
    typeB_feat_count <- as.integer(sum(resultsB == 1))
    
    #print(paste0("c",typeA_feat_count))
    #print(paste0("d",typeB_feat_count))
    
    
    typeA_prop <- typeA_feat_count/typeA_count
    typeB_prop <- typeB_feat_count/typeB_count
    
    #print(paste0("e",typeA_prop))
    #print(paste0("f",typeB_prop))
    
    A_E <- typeA_feat_count
    A_D <- typeA_count - typeA_feat_count
    B_E <- typeB_feat_count
    B_D <- typeB_count - typeB_feat_count
    
    cont <- matrix(c(A_E,A_D,B_E,B_D), nrow=2, ncol=2)
    
    ftest <- fisher.test(cont)
    #print(paste(name,ftest$p.value))
    
    pval <- ftest$p.value
    
    if (pval < 0.05) {
      if (typeA_prop > typeB_prop) {
        sig <- "A"
      } else {
        sig <- "B"
      }
    } else {
      sig <- "N"
    }
    
    if (typeA_prop > 0.05 | typeB_prop > 0.05) {
      rowA <- data.frame(paste0(name,"_A"), name, "A", typeA_prop, pval, sig)
      rowB <- data.frame(paste0(name,"_B"), name, "B", typeB_prop, pval, sig)
      rowSig <- data.frame(name, pval, sig)
      
      df_prop_sumA <- rbind(df_prop_sumA, rowA)
      df_prop_sumB <- rbind(df_prop_sumB, rowB)
      df_sig <- rbind(df_sig,rowSig)
    }
    
    #          Type A  Type B
    # Exist      1       3
    # Doesnt     2       4
    # 
    
  }
  colnames(df_prop_sumA) <- c("ID","Feature", "Type", "Prop", "PVal", "Sig")
  colnames(df_prop_sumB) <- c("ID","Feature", "Type", "Prop", "PVal", "Sig")
  colnames(df_sig) <- c("Feature", "PVal", "Sig")
  df_prop_sum <- rbind(df_prop_sumA, df_prop_sumB)
  
  
  get_colo <- function(x) {
    
    if(x == "B") {
      return ("#00BFC4")
    } else if (x == "A") { 
      return("#F8766D") 
    } else {
      return("black") 
    }
  }
  a <- sapply(df_sig$Sig, get_colo)
  
  
  # Conversion to factor necessary to maintain order for GGPlot
  df_prop_sum$Feature <- factor(df_prop_sum$Feature, levels=unique(df_prop_sum$Feature))
  
  #df_sig_trun <- data.frame(matrix(vector(),0,2,dimnames=list(c(), c("Feature", "Sig"))), stringsAsFactors = F)
  #df_sig_trun <- df_sig_trun[c("Feature", "Sig")]
  
  #print(df_sig[c("Feature", "Sig")])
  
  write.table(df_sig[c("Feature", "Sig")], file = paste0("PPCG",region,"_",cluster_type,"_feature_proportion_details.txt"), sep="\t",quote=F, row.names = FALSE)
  
  pl <- ggplot(data = df_prop_sum, aes(x = reorder(Feature,-Feature), y = Prop, fill = Type)) +
    geom_bar(stat="identity", position=position_dodge()) +
    coord_flip() +
    theme_bw() +
    scale_y_continuous("Proportion of samples", breaks=c(0.00, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00)) +
    xlab("Summary measurement") +
    theme(axis.text.y = element_text(colour = a))

  
  # pl <- ggplot(data = df_prop_sum, aes(x = reorder(Feature,-Feature), y = Prop, fill = Type)) +
  #   geom_bar(stat="identity", position=position_dodge()) +
  #   theme_bw() +
  #   ylab("Proportion of samples") +
  #   xlab("Summary measurement") +
  #   theme(axis.text.x = element_text(size=rel(1.5), angle = 90, vjust = 0.5, hjust = 1, colour = a),
  #         axis.text.y = element_text(size=rel(1.5)),
  #         axis.title.y = element_text(size=rel(1.5)),
  #         axis.title.x = element_text(size=rel(1.5)),
  #         legend.position = c(0.95,0.8)
  #         )
  # 
 pl
  #ggsave(paste0("PPCG",region,"_",cluster_type,"_feature_proportion_flipped.png"),plot = pl)


  
  ggsave(paste0("PPCG",region,"_",cluster_type,"_feature_proportion.png"),plot = pl)
}

#region, cluster_type, flip
#print(df_prop_sum$Feature)


#region <- ""



#flip <- "flip"
#flip <- ""

#"France"
#"Germany"
#"UK"
#"Australia"
#"Canada"
#"Denmark"

#region, cluster_type, flip
# plot_feature_proportion("","Clust_Type","flip")
plot_feature_proportion("","Clust_FinType2","")
# plot_feature_proportion("","Clust_FinType2","")
# plot_feature_proportion("","CA_arbs","")
# plot_feature_proportion("","CA_tm_ppcg1","flip")
# plot_feature_proportion("","CA_tm_ppcg2","flip")
# plot_feature_proportion("","CA_pca","")
# plot_feature_proportion("","CA_tsne","flip")
# plot_feature_proportion("","CA_som","")
# plot_feature_proportion("","CA_ae","flip")
# plot_feature_proportion("","CA_umap","flip")


# plot_feature_proportion("France","Clust_FinType2","")
# plot_feature_proportion("Germany","Clust_FinType2","")
# plot_feature_proportion("UK","Clust_FinType2","")
# plot_feature_proportion("Australia","Clust_FinType2","")
# plot_feature_proportion("Canada","Clust_FinType2","")
# plot_feature_proportion("Denmark","Clust_FinType2","")



#cluster_type <- "CA_arbs"
#cluster_type <- "CA_tm_ppcg1"
#cluster_type <- "CA_tm_ppcg2"
#cluster_type <- "CA_tm_ppcguk"
#cluster_type <- "evo_results"
#cluster_type <- "CA_pca"

#cluster_type <- "CA_som"
#cluster_type <- "CA_ae"
#cluster_type <- "CA_umap"
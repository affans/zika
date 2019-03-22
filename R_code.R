organize_data <- function(fname="micro.dat"){
  cnl = list("Belize", "Boliva","Brazil","Colombia","CostaRica", "Ecuador",
             "ElSalvador", "FrenchGuiana", "Guatemala", "Guyana", "Honduras",
             "Mexico", "Nicaragua", "Panama", "Paraguay", "Peru", "Suriname", 
             "Venezuela")
  
  for (cn in cnl){
    fn_nv = paste0(cn, "-novaccine-", fname)
    fn_wv = paste0(cn, "-wivaccine-", fname)
    

    dir.create("isodata")
    
    a = file.path(".", cn)
    ddir = list.files(a)
    for (d in ddir){
      pp = file.path(a, d, fname)
   
      pr = substr(unlist(strsplit(d, "_"))[2], 9, 10)
      if (pr == "00"){
        file.copy(pp, file.path("./isodata", fn_nv))
      } else {
        file.copy(pp, file.path("./isodata", fn_wv))
      }
    }
  }

}




# ------------- Fetching data from NCBI -------------

require(httr) 
require(XML)

# Get details for some GSE projects fron NCBI website
Query_Prefix <- "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc="
GSE_IDs <- c("GSE63312", "GSE78224", "GSE74018", "GSE50734", "GSE114644", "GSE60477", "GSE53599", "GSE80582", "GSE109493", "GSE35200")

Tags <- c("Title", "Summary", "Organism", "Experiment type", "Overall design", "Citation(s)")
Values <- vector(mode = "list", length = length(Tags))
DataMatrix <- as.data.frame(matrix(nrow=length(Tags),ncol=length(GSE_IDs)+1))
colnames(DataMatrix)=c("Field", GSE_IDs)
DataMatrix$Field <- Tags
   
# Fetching HTML Page & parsing for the required tags ; Title, summary, organisms, experiment type, overall design and citations.
for(i in 1:length(GSE_IDs)){
      tURL <- paste(Query_Prefix, GSE_IDs[i], sep = "")
      html <- GET(tURL)
      warn_for_status(html) # Throws warning if failed to retrieve the page
      print(tURL)
      Page_contents <- content(html, as="text")
      parsed_HTML <- htmlParse(Page_contents, asText = TRUE)
      
      for(j in 1:length(Tags)){
         Tag = paste("[td='", Tags[j],"']", sep = "")
         Query <- paste("//body//table[1]//tr[@valign='top']", Tag, sep = "")
         Yp <- xpathSApply(parsed_HTML, Query, xmlValue)   
         Values[j] <- as.character(strsplit(as.character(Yp[[1]]), "\n")[[1]][2])
      }
      ColName <- GSE_IDs[1]
      DataMatrix[,i+1] = unlist(Values)
}

# ------------ Add Annotations to summary ------------------
require(jsonlite)
API_becas = "http://bioinformatics.ua.pt/becas/api/text/annotate?email=<shindetejus@gmail.com>&tool=<DbCreationApp>"

Text_Str <- as.character(DataMatrix[2,2])
tSTR <- paste("{ 'groups': { 'DISO': true, 'PRGE': true, 'PATH':true}, 'text' : {", Text_Str, "}",sep="" )
groups <- toJSON(tSTR, pretty=T) 

JSON_Obj <- POST(API_becas, body = groups, encode = "json", add_headers("Content-Type" = "application/json"))
CJSON <- jsonlite::fromJSON(rawToChar(JSON_Obj$content))

# ------------ Add Data to MySQL Database ------------------

library(DBI); require(RMySQL)
# Connect to Db
con <- dbConnect(RMySQL::MySQL(), dbname = "geo_datasets",host = "localhost", password=pwd, user="root", port=3306)

# Blank Database Connection Established
dbListTables(con)

# Add Data to Db
dbWriteTable(con, "mtcars", mtcars)

# You can fetch all results:
res <- dbSendQuery(con, "SELECT * FROM mtcars WHERE cyl = 4")
dbFetch(res)
dbClearResult(res)


# Disconnect from the database
dbDisconnect(con)




'
Script does 3 things :
   1.) Gets basic info for some sequencing projects using GSE IDs from NCBI website
   2.) Annotates the summary info from above scraped data using becas apis
   3.) Creates a database and adds the fetched data into it. Also added some query"s to
   fetch & retrieve data
   

'

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
      Page_contents <- content(html, "text", encoding = "UTF-8")
      parsed_HTML <- htmlParse(Page_contents, asText = TRUE, encoding = "UTF-8")

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
   
   # Getting the summary from the above scraped data
   Text_Str <- as.character(DataMatrix[2,9])
   IList <- list('groups' = "'DISO': true, 'PRGE': true, 'PATH':true", 'text' = Text_Str, "format"= "json" )
   groups <- toJSON(IList)
   
   # Using the API for annotation
   JSON_Obj <- POST(API_becas, body = groups, add_headers("Content-Type" = "application/json"))
   # There is some problem. I keep getting error code 500; Referring to their server error.
   JSON_Obj[2]
   
   # Anyway after getting back JSON obj 1 way would be to use jsonlite pckg to convert each element of JSON into list and identify the required data. Probably will have to do some string splitting too
   CJSON <- jsonlite::fromJSON(rawToChar(JSON_Obj$content))

# Proceeding with just adding the scraped data

# ------------ Add Data to MySQL Database ------------------

      library(DBI); require(RMySQL)
      # Connect to Db
      pwd="mysqlpwd"
      con <- dbConnect(RMySQL::MySQL(), dbname = "geo_datasets",host = "localhost", password=pwd, user="root", port=3306)
      
      # Blank Database Connection Established
      dbListTables(con)
      
      # Add Data to Db
      
      Count_Datasets <- dim(DataMatrix)[2] - 1
      CNames <- colnames(DataMatrix)
      
      # Index Table
      Sr <- seq(1:Count_Datasets)
      
      tempDf <- data.frame("IDVar" = Sr, "Datatables" = GSE_IDs)
      #dbWriteTable(con, "Contents", tempDf, overwrite= TRUE)
      
      # Added table name can be seen here
      dbListTables(con)
      
      # You can add the whole data into 1 matrix with
      #dbWriteTable(con, "RNA_Seq_Data", DataMatrix, overwrite= TRUE)
      
      
      # Creating separate data tables in the Data base for each with this loop
      for(i in c(7:10)){
         tempColName <- CNames[i]
         tempDf <- data.frame(DataMatrix[,1], DataMatrix[,i])
         colnames(tempDf) <- c("Section", tempColName)
         print(dim(tempDf))
         print(tempColName)
         dbWriteTable(con, tempColName, tempDf, overwrite= TRUE)   
      }
      
      # Db added
      dbListTables(con)
      '
       [1] "contents"     "gse109493"    "gse114644"    "gse50734"     "gse53599"    
       [6] "gse60477"     "gse74018"     "gse78224"     "gse80582"     "mtcars"      
      [11] "rna_seq_data"
      '
      
      
# You can fetch all results by constructing a query & sending it like this:
# Query 1
#res <- dbSendQuery(con, "DROP TABLE RNA_Seq_Data")
   dbFetch(res)
   dbClearResult(res)
   
   # Query 2
   res <- dbSendQuery(con, "SELECT * from contents")
   dbFetch(res)
'
   row_names IDVar Datatables
1          1     1   GSE63312
2          2     2   GSE78224
3          3     3   GSE74018
4          4     4   GSE50734
5          5     5  GSE114644
6          6     6   GSE60477
7          7     7   GSE53599
8          8     8   GSE80582
9          9     9  GSE109493
10        10    10   GSE35200

'

      # Query 3
      res <- dbSendQuery(con, "SELECT * from gse78224")
      dbFetch(res)

' row_names         Section
1         1           Title
2         2         Summary
3         3        Organism
4         4 Experiment type
5         5  Overall design
6         6     Citation(s)
                                                                                                              GSE78224
1 BET inhibition releases the Mediator complex from specific cis elements in acute myeloid leukemia cells (RNA-Seq II)
2                                                             Genome occupancy profiling by high throughput sequencing
3                                                                                                         Mus musculus
4                                                                   Expression profiling by high throughput sequencing
5                   PolyA selected RNA-seq for shRNA-expressing MLL-AF9 transformed acute myeloid leukemia cells (RN2)
6                                                                                                             27068464
'
         # Disconnect from the database
         dbDisconnect(con)




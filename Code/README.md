# Database_Creation

## Objective : 
1. To scrape all the relevant information from the GEO website for provided GSE IDs and store it into a database of your choice. 
2. After creating the database we have to annotate the `biological keywords` in the summary & store the annotated keywords of each dataset within the Database 
3. Write a query to get all the dataset IDs which contain disease keyword.

__GSE IDs:__ _GSE63312, GSE78224, GSE74018, GSE50734, GSE114644, GSE60477, GSE53599, GSE80582, GSE109493, GSE35200_

## Achieved properly
Script does 3 things :
   1.) Gets basic info for some sequencing projects using GSE IDs from NCBI website
   2.) Failes to annotates the summary info from above scraped data using becas apis due to some server error from their side
   3.) Creates a database and adds the fetched data into it. Also added some query"s to
   fetch & retrieve data
   
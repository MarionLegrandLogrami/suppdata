.suppdata.plos <- function(doi, si, save.name=NA, dir=NA, cache=TRUE, ...){
    #Argument handling
    if(!is.numeric(si))
        stop("PLoS download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    
    #Find journal from DOI
    journals <- setNames(c("plosone", "plosbiology", "plosmedicine",
                           "plosgenetics", "ploscompbiol", "plospathogens",
                           "plosntds"),
                         c("pone", "pbio", "pmed", "pgen", "pcbi",
                           "ppat", "pntd"))
    
    journal <- gsub("[0-9\\.\\/]*", "", doi)
    journal <- gsub("journal", "", journal)
    if(sum(journal %in% names(journals)) != 1)
        stop("Unrecognised PLoS journal in DOI ", doi)
    journal <- journals[journal]

#Download and return
    destination <- file.path(dir, save.name)
    url <- paste0("http://journals.plos.org/", journal,
                  "/article/asset?unique&id=info:doi/", doi, ".s",
                  formatC(si, width=3, flag="0"))
    return(.download(url, dir, save.name, cache))
}

#' @importFrom httr timeout GET
#' @importFrom xml2 read_html xml_attr xml_find_all
.suppdata.wiley <- function(doi, si, save.name=NA, dir=NA,
                            cache=TRUE, timeout=10, ...){
    #Argument handling
    if(!is.numeric(si))
        stop("Wiley download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)

    # Download SI HTML page and find SI link
    html <- tryCatch(as.character(
        GET(paste0("https://onlinelibrary.wiley.com/doi/full/", doi),
            httr::timeout(timeout))), silent=TRUE, error = function(x) NA)
    
    links <- gregexpr('downloadSupplement\\?doi=[0-9a-zA-Z\\%;=\\.&-]+', html)
    # Check to see if we've failed (likely because it's a weird data journal)
    if(links[[1]][1] == -1){
        html <- tryCatch(as.character(
            GET(paste0("https://onlinelibrary.wiley.com/doi/abs/", doi),
                httr::timeout(timeout))), silent=TRUE, error = function(x) NA)
        links <- gregexpr('downloadSupplement\\?doi=[0-9a-zA-Z\\%;=\\.&-]+', html)
        if(links[[1]][1] == -1)
            stop("Cannot find SI for this article")
    }
    links <- substring(html, as.numeric(links[[1]]),
                       links[[1]]+attr(links[[1]],"match.length")-1)
    links <- paste0("https://onlinelibrary.wiley.com/action/", links)

    if(si > length(links))
        stop("SI number '", si, "' greater than number of detected SIs (",
             length(links), ")")
    url <- links[si]
    
    #Download and return
    destination <- file.path(dir, save.name)
    return(.download(url, dir, save.name, cache))
}

#' @importFrom jsonlite fromJSON
#' @importFrom xml2 xml_text xml_find_first
#' @importFrom httr content
.suppdata.figshare <- function(doi, si, save.name=NA, dir=NA,
                               cache=TRUE, ...){
    #Argument handling
    if(!(is.numeric(si) | is.character(si)))
        stop("FigShare download requires numeric or character SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    
    #Find, download, and return
    html <- read_html(content(GET(paste0("https://doi.org/", doi)), "text"))
    results <- fromJSON(xml_text(xml_find_first(html,
                          "//script[@type=\"text/json\"]")))$article$files
    if(is.numeric(si)){
        if(si > nrow(results))
            stop("SI number '", si, "' greater than number of detected SIs (",
                 nrow(results), ")")
        suffix <- strsplit(results$name[si], "\\.")[[1]]
        suffix <- suffix[length(suffix)]
        return(.download(results$downloadUrl[si],dir,save.name,cache,suffix))
    }
    if(!si %in% results$name)
        stop("SI name not in files on FigShare (which are: ",
             paste(results$name,collapse=","), ")")
    suffix <- strsplit(results$name[si], "\\.")[[1]]
    suffix <- suffix[length(suffix)]
    return(.download(results$downloadUrl[results$name==si], dir,
                     save.name, cache, suffix))
}

.suppdata.esa_data_archives <- function(esa, si, save.name=NA, dir=NA,
                                        cache=TRUE, ...){
    #Argument handling
    if(!is.character(si))
        stop("ESA Archives download requires character SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(esa, save.name, si)

    #Download, and return
    esa <- gsub("-", "/", esa, fixed=TRUE)
    return(.download(paste0("http://esapubs.org/archive/ecol/", esa, "/data",
                            "/", si), dir, save.name, cache))
}
.suppdata.esa_archives <- function(esa, si, save.name=NA, dir=NA,
                                   cache=TRUE, ...){
    #Argument handling
    if(!is.character(si))
        stop("ESA Archives download requires character SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(esa, save.name, si)

    #Download, and return
    esa <- gsub("-", "/", esa, fixed=TRUE)
    return(.download(paste0("http://esapubs.org/archive/ecol/",esa,"/",si),
                     dir, save.name, cache))
}

.suppdata.science <- function(doi, si, save.name=NA, dir=NA,
                              cache=TRUE, ...){
    #Argument handling
    if(!is.character(si))
        stop("Science download requires character SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)

    #Find, download, and return
    url <- paste0("http://www.sciencemag.org",
                  .grep.url(paste0("http://www.sciencemag.org/lookup/doi/",doi),
                            "(/content/)[0-9/]*"), "/suppl/DC1")
    url <- paste0("http://www.sciencemag.org",
                  .grep.url(url, "(/content/suppl/)[A-Z0-9/\\.]*"))
    return(.download(url, dir, save.name, cache))
}

.suppdata.proceedings <- function(doi, si, vol, issue, save.name=NA, dir=NA,
                                  cache=TRUE, ...){
    #Argument handling
    if(!is.numeric(si))
        stop("Proceedings download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    
    #Find, download, and return
    journal <- .grep.text(doi, "(rsp)[a-z]")
    tail <- gsub(".", "", .grep.text(doi, "[0-9]+\\.[0-9]*", 2), fixed=TRUE)
    url <- paste0("http://", journal, ".royalsocietypublishing.org/content/",
                  vol, "/", issue, "/", tail, ".figures-only")
    url <- paste0("http://rspb.royalsocietypublishing.org/",
                  .grep.url(url, "(highwire/filestream)[a-zA-Z0-9_/\\.]*"))
    return(.download(url, dir, save.name))
}

#' @importFrom xml2 xml_text xml_find_first read_xml
.suppdata.epmc <- function(doi, si, save.name=NA, dir=NA,
                           cache=TRUE, list=FALSE, ...){
    #Argument handling
    if(!is.character(si))
        stop("EPMB download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    zip.save.name <- .save.name(doi, NA, "raw_zip.zip")
    
    #Find, download, and return
    pmc.id <- xml_text(xml_find_first(read_xml(
        paste0("https://www.ebi.ac.uk/europepmc/webservices/rest/search/query=",
               doi)), ".//pmcid"))
    url <- paste0("https://www.ebi.ac.uk/europepmc/webservices/rest/",
                  pmc.id[[1]], "/supplementaryFiles")
    zip <- tryCatch(.download(url,dir,zip.save.name,cache),
                    error=function(x)
                        stop("Cannot find SI for EPMC article ID ",pmc.id[[1]]))
    return(.unzip(zip, dir, save.name, cache, si, list))
}

.suppdata.biorxiv <- function(doi, si, save.name=NA, dir=NA,
                              cache=TRUE, ...){
    #Argument handling
    if(!is.numeric(si))
        stop("bioRxiv download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    
    #Find, download, and return
    url <- paste0(.url.redir(paste0("https://doi.org/", doi)), ".figures-only")
    file <- .grep.url(url, "/highwire/filestream/[a-z0-9A-Z\\./_-]*", si)
    return(.download(.url.redir(paste0("http://biorxiv.org",file)),
                     dir, save.name, cache))
}

#' @importFrom utils URLencode
.suppdata.dryad <- function(doi, si, save.name=NA, dir=NA,
                            cache=TRUE, ...){
    #Argument handling
    if(!is.character(si))
        stop("DataDRYAD download requires numeric SI info")
    dir <- .tmpdir(dir)
    save.name <- .save.name(doi, save.name, si)
    
    #Find, download, and return
    url <- .url.redir(paste0("https://doi.org/", doi))
    file <- .grep.url(url, paste0("/bitstream/handle/[0-9]+/dryad\\.[0-9]+/",
                                  URLencode(si,reserved=TRUE)))
    return(.download(.url.redir(paste0("http://datadryad.org",file)),
                     dir, save.name, cache))
}

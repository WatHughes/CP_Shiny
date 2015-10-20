# library(rdrop2) # Dropbox wrapper
# library(data.table)

# Some cleanup is needed.
# For now this needs globals:
# CompressedRDataDir
# DropBoxCompressedRDataDir
# BLSDataURL
# QuietDownload
# OrigDataDir
# MaxRowsToRead

LoadDataFile = function(FileName) # First downloads the file unless it is already local
{
    Note=''
    StartTime = proc.time()
    CompressedRDataPath = paste0(CompressedRDataDir,'/',FileName,'.rda')
    DropBoxCompressedRDataPath = paste0(DropBoxCompressedRDataDir,'/',FileName,'.rda')
    if (!file.exists(CompressedRDataPath) & drop_exists(DropBoxCompressedRDataPath))
    {
        # This is the case where we don't have the file locally as required by load()
        # but it is on DropBox. Download the file so we can use it locally.
        drop_get(DropBoxCompressedRDataPath, CompressedRDataPath)
        Note=paste0(Note,'Dowloaded RDA from DropBox. ')
    }
    if (file.exists(CompressedRDataPath))
    {
        load(CompressedRDataPath,.GlobalEnv) # Load it in the global environment. The RDA file was created to contain 1 data.table with the name indicated by FileName.
        Note = paste0(Note,'Loaded compressed data.table ',FileName,'.')
    }
    else
    {
        FilePath = paste(OrigDataDir, FileName, sep='/')
        # The file must be local for file.size. Plus, we use both read.table and fread so may
        # as well download it.
        if (file.exists(FilePath))
        {
            Note = paste0(FileName, ' already local.')
        }
        else
        {
            Note = paste0(FileName, ' downloaded from BLS.')
            FileURL = paste(BLSDataURL, FileName, sep='/')
            download.file(FileURL, FilePath, mode='wb',quiet=QuietDownload)
        }
        # fread ignores the first line of these codetables because that
        # header doesn't have the trailing tab (blank column) of the data rows.
        # So read.table is used to get the variable names.
        # But read.table is slow and also won't handle the Windows format text lines
        # on the Linux Shiny server at shinyapps.io,
        # so fread is used to actually load the data. Then then variable names are fixed up.
        namesDF = read.table(FilePath,header=F,nrows=1,sep='\t',row.names=NULL,stringsAsFactors=F)
        if (file.size(FilePath) > 999999)
        {
            drop = NULL
        }
        else
        {
            drop = ncol(namesDF) + 1
        }
        assign(FileName,fread(FilePath,nrows=MaxRowsToRead,header=F,drop=drop),envir=.GlobalEnv)
        setnames(get(FileName), colnames(get(FileName)), as.matrix(namesDF)[1,])
    }

    LoadTime = proc.time()
    LoadTime = LoadTime - StartTime
    print(Note)
    print('Data loaded in:')
    print(LoadTime)
    get(FileName)
} # LoadDataFile

# If a variable exists with the name in FileName, return it. Otherwise,
# load it using LoadDataFile.

CondLoadDataTable = function(FileName)
{
    mget(FileName,ifnotfound=list(LoadDataFile),inherits=T)[[1]]
    # <sigh> get0 was running LoadDataFile even when FileName was found!
} # CondLoadDataTable

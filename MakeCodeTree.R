# This is mean to be sourced by projects that need it.
# The calling file should

library(rlist)

# Many of the BLS code tables encode a hierarchy using sort_sequence and
# display_level. This routine builds the corresponding tree structure. This data
# structure will be useful for the GUI. There are two phases. First the parent
# row numbers are computed. Then these drive the actual tree building.
# Conventional (C++, etc.) recursive approaches don't work in R because there
# are no reasonable 'back pointers' into the tree in progress.
# Note: there was some development complexity due to data.table's non standard
# lazy copy functionality.

MakeCodeTree = function(CodeData,MaxDepth=999999) # data.table version of an appropriate BLS code table.
{
    # For performance, limit the maximum depth of the tree data and thereby the control
    MyMaxDepth = MaxDepth
    # This will be sorted by sort_sequence then 2 variables will be added, rn and parent_rn.
    AugmentedCodeData = CodeData
    # The column number of the descritptive field, e.g., industry_text.
    DisplayTextColumn = grep('_text$',names(CodeData))
    DisplayTextColumnName = names(CodeData)[DisplayTextColumn] # Guess
    # The column number of the BLS code field, e.g., industry_code.
    CodeColumn = grep('_code$',names(CodeData))
    CodeColumnName = names(CodeData)[CodeColumn] # Guess
    # This will be a list with 2 named elements. "me" will contain the first record of the
    # code table. "children" will be a list of similar 2 elements lists, each of which
    # corresponds to the direct children of the first element/row. Repeat for each element
    # of children until there's no more data.
    CachedCodeTree = NULL
    # This will be a nested list. The list structure is converted to the displayed tree
    # structure by shinyTree with the element names becoming node display text and with
    # non list valued element values ignored. Non list valued element's names are leaves.
    CachedDisplayTree = NULL

    GetAugmentedCodeData = function()
    {
        CondCacheCodeTree() # If needed calls CacheParentRNs() which adds variables rn and parent_rn
        AugmentedCodeData
    } # GetAugmentedCodeData

    GetDisplayTextColumn = function()
    {
        DisplayTextColumn
    }

    GetCodeColumn = function()
    {
        CodeColumn
    }

    GetCodeTree = function()
    {
        CondCacheCodeTree()
        CachedCodeTree
    } # GetCodeTree

    GetDisplayTree = function()
    {
        CondCacheDisplayTree()
        # browser() # Breakpoints seem a little flaky in Shiny.
        CachedDisplayTree
    } # GetDisplayTree

    CondCacheCodeTree = function() # And also AugmentedCodeData
    {
        if (is.null(CachedCodeTree))
        {
            MyAugmentedCodeData = ComputeParentRNs()
            AugmentedCodeData <<- MyAugmentedCodeData
            MyCodeTree = PopulateSubTree(1)
            CachedCodeTree <<- MyCodeTree
        }
    } # CondCacheCodeTree

    ComputeParentRNs = function() # Phase 1
    {
        acd = copy(AugmentedCodeData) # So as to not change the original code table in the parent environment
        setkey(acd,sort_sequence) # This needs to be executed after we force a local copy of the dt
        MaxRow = nrow(acd)
        acd[,rn:=1:MaxRow] # Will compute each row's Parent RowNum and put it here
        acd[,parent_rn:=0] # Will compute each row's Parent RowNum and put it here

        CurrentDisplayLevel = 0

        for(RowNum in 2:MaxRow)
        {
            dl = acd[RowNum,]$display_level
            if (dl == CurrentDisplayLevel)
            {
                acd[RowNum,]$parent_rn = acd[RowNum-1,]$parent_rn
            } else if (dl > CurrentDisplayLevel) # Moving down the tree, so this node is a child
            {
                if (dl >= MyMaxDepth) # Then clip the tree by setting parent to negative of real value
                {
                    acd[RowNum,]$parent_rn = -(RowNum-1)
                }
                else
                {
                    acd[RowNum,]$parent_rn = RowNum-1
                }
                CurrentDisplayLevel = dl
            } else # Jumping back up to a different branch
            {
                CondSiblingRowNum = RowNum-1
                # browser()
                while(dl < CurrentDisplayLevel)
                {
                    CondSiblingRowNum = abs(acd[CondSiblingRowNum,]$parent_rn)
                    CurrentDisplayLevel = acd[CondSiblingRowNum,]$display_level
                }
                acd[RowNum,]$parent_rn = acd[CondSiblingRowNum,]$parent_rn
            }
        } # Parent row number loop

        # acd as computed here when called with rl.industry as the input:
        # Classes ‘data.table’ and 'data.frame':	1281 obs. of  8 variables:
        #  $ industry_id  : int  1 1249 1252 1253 7 2 3 4 5 6 ...
        #  $ industry_code: chr  "000000" "GP1AAA" "GP1NRM" "GP2AFH" ...
        #  $ industry_text: chr  "All workers" "Goods-producing" "Natural resources and mining" "Agriculture, forestry, fishing and hunting" ...
        #  $ display_level: int  0 1 2 3 4 5 5 5 5 5 ...
        #  $ selectable   : logi  TRUE TRUE TRUE TRUE TRUE TRUE ...
        #  $ sort_sequence: int  1 2 3 4 5 6 16 20 31 38 ...
        #  $ rn           : int  1 2 3 4 5 6 7 8 9 10 ...
        #  $ parent_rn    : num  0 1 2 3 4 5 5 5 5 5 ...
        #  - attr(*, ".internal.selfref")=<externalptr>
        #  - attr(*, "sorted")= chr "sort_sequence"
        acd
    } # ComputeParentRNs

    PopulateSubTree = function(RowNum) # And all children, recursively. Phase 2
    {
        CurrentCodeDef = AugmentedCodeData[RowNum,]
        ret = list(me=CurrentCodeDef,children=list())
        ChildrenRNs = which(AugmentedCodeData$parent_rn == RowNum)
        for(ThisChildRN in ChildrenRNs)
        {
            ThisChildSubTree = PopulateSubTree(ThisChildRN)
            ret[[2]] = list.append(ret[[2]],ThisChildSubTree)
            cl = length(ret[[2]])
            rl = length(ret)
        }
        ret
    } # PopulateSubTree

    CondCacheDisplayTree = function()
    {
        CondCacheCodeTree()
        if (is.null(CachedDisplayTree))
        {
            CachedDisplayTree <<- list( # Junk development code
                '1' = '',
                '2' = list(
                    '3' = list(leaf1 = '', leaf2 = '', leaf3=''),
                    '4' = list(leafA = '', leafB = '')
                )
            )
            DefinedTopLevelRN = 1
            CachedDisplayTree <<- PopulateSubDisplayTree(DefinedTopLevelRN) # Real code
        }
    } # CondCacheDisplayTree

    PopulateSubDisplayTree = function(RowNum) # And all children, recursively. Phase 3
    {
        ret = list('') # Any non list element signals to ShinyTree this a leaf.
        CurrentCodeDef = AugmentedCodeData[RowNum,]
        CurrentDisplayText = CurrentCodeDef[1,DisplayTextColumn,with=F]
        CurrentDisplayText = as.character(CurrentDisplayText)
        # browser()
        ChildrenRNs = which(AugmentedCodeData$parent_rn == RowNum)
        FirstTime = T
        for(ThisChildRN in ChildrenRNs)
        {
            ThisChildSubTree = PopulateSubDisplayTree(ThisChildRN)
            ThisChildCodeDef = AugmentedCodeData[ThisChildRN,]
            ThisChildDisplayText = ThisChildCodeDef[1,DisplayTextColumn,with=F]
            ThisChildDisplayText = as.character(ThisChildDisplayText)
            if (FirstTime)
            {
                FirstTime = F
                ret[[1]] = ThisChildSubTree # Replacing '' as the first element
                # names(ret[[1]]) = ThisChildDisplayText
            }
            else
            {
                ret[[1]] = list.append(ret[[1]],ThisChildSubTree[[1]])
                names(ret[[1]])[length(names(ret[[1]]))] = ThisChildDisplayText
            }
        }
        names(ret) = CurrentDisplayText
        ret
    } # PopulateSubDisplayTree

    GetSelectedCodeDef = function(ShinyTreeSelected) # See app.R for an example of ShinyTreeSelected
    {
        RowNum = 0
        ret = NULL
        if (length(ShinyTreeSelected) > 0) # Remove the selection containing list
        {
            ShinyTreeSelected = ShinyTreeSelected[[1]]
            while(is.list(ShinyTreeSelected)) # Walk down the tree
            {
                RootDisplayText = names(ShinyTreeSelected) # Matching display text
                Children = AugmentedCodeData[parent_rn == RowNum] # among the children of RowNum
                RowNum = Children[which(Children[,DisplayTextColumn,with=F]==RootDisplayText),]$rn
                ret = AugmentedCodeData[RowNum,]
                ShinyTreeSelected = ShinyTreeSelected[[1]]
            }
        }
        if (is.null(ret))
        {
            # Default to the 'All' entry
            CurrentCodeDef = AugmentedCodeData[1,]
            ret = CurrentCodeDef
        }
        ret
    } # GetSelectedCodeDef

    # These are the only public methods for a CodeTree

    list(GetAugmentedCodeData = GetAugmentedCodeData, # This method is intended for troubleshooting or EDA
         GetCodeTree = GetCodeTree, # This returns the code tree as a nested list, building it and caching it if needed
         GetDisplayTree = GetDisplayTree, # This returns the display text tree as a nested list, building it and caching it if needed
         GetSelectedCodeDef = GetSelectedCodeDef, # This returns the selected record from the (augmented) BLS code table, e.g. rl.industry (augmented with rn and parent_rn)
         GetDisplayTextColumn = GetDisplayTextColumn, # This returns the column number of the variable that holds the display text for the BLS code
         GetCodeColumn = GetCodeColumn # This returns the column number of the variable field that holds the actual BLS code itself
    )
} # MakeCodeTree

# ct = MakeCodeTree(rl.industry)
# tct = ct$GetCodeTree()
# ct3 = MakeCodeTree(rl.industry,3)
# tct3 = ct3$GetCodeTree()

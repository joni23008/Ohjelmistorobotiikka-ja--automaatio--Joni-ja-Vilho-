def isEqual(header, row, maxDifference):
    if ( abs(header-row) <= maxDifference ):
        return True
    return False
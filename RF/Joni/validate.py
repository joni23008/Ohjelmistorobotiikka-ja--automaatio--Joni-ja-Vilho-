def isEqual(headerTotal, rowTotal, maxDifference):
    if ( abs(headerTotal-rowTotal) <= maxDifference ):
        return True
    return False
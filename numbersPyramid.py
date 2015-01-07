__author__ = 'Chandan'

def pyramid(p):

    i=1
    j=1
    k=1
    level = findLevel(p)

    for i in range(level+1):
        print " "*(level+1-i),
        for j in range(i):
            print "%d "%(k),
            print " "*(fillspace(p)-fillspace(k)),
            k +=1
        print "\n"

def findLevel(p):

    tot = 0
    for i in range(100):
        tot = (i* (i+1))/2
        if tot > p:
            print "Level: %d "%(i)
            return i

def fillspace(num):

    if num > 0 and num <= 9:
        return 1
    elif num > 9 and num <= 99:
        return 2
    elif num > 99 and num <= 999:
        return 3
    else:
        raise Exception("Number should be below 1000")

if __name__ == "__main__":

    pyramid(151)
    print "\n END \n"

#!/usr/bin/env python
#from subprocess import call
import os
import subprocess
with open("/home/zaidm/ZaidM/compareskutoimages/catalog_product_entity.txt") as f:
    skulist = f.read().splitlines()
#list = output.splitlines()
#print skulist

with open("/home/zaidm/ZaidM/compareskutoimages/lsz2.txt") as f:
    imglist = f.read().splitlines()
#print imglist
#for filenm in bucketlist:
#    print filenm + "end"

for filenm in skulist:
#    print filenm + "endlist"
    if filenm in imglist:
        a=1
    else:
        print "no " + filenm

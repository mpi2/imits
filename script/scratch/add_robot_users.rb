#!/usr/bin/env ruby

#Issue #9313 has been reported by Vivek Iyer.
#
#----------------------------------------
#Task #9313: create 'robot' users for (most) production centres
#http://htgt.internal.sanger.ac.uk:4005/issues/9313
#
#Author: Vivek Iyer
#Status: New
#Priority: Immediate
#Assignee: Richard Easty
#Category:
#Target version: 2012 November 2
#Related RT Ticket:
#Sprint:
#
#
#There are a number of production centres, who - like us - need 'robot' users. Create these, assigning them to the various centres:
#
#ICS
#Harwell
#JAX
#UCD
#TCP
#BCM
#CNR
#... let's make one user PER centre.
#Password - make it random in production
#
#1) After this is done, do a rake db:production:clone from live => staging
#AND a
#2) rake db:password:reset
#
#so that the ROBOT users have 'password' set into the staging environment. This will mean that users in Toronto can try API out  stuff using the robot users, TOMORROW.


# for each centre
# add robot user if not already there
# set password to password
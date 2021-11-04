#!/bin/bash

while getopts e: flag
do
    case "${flag}" in
        e) experiment=${OPTARG};;
    esac
done

echo '[CONCIERGE] STARTING CLEANING PROCESS'

rm -R -- ./experiments/$experiment/*

echo '[CONCIERGE] DO YOU SMELL THAT? THE SMELL OF CLEAN\nI AM DONE SIR'
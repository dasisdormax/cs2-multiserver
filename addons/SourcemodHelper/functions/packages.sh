#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodHelper::loadPackage () {
	echo "Loading package $1 ..."
	: ../packages/$1
	SourcemodPackage.$1::download
}

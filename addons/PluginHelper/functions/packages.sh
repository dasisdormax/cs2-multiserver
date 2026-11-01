#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

PluginHelper::loadPackage () {
	echo "Loading package $1 ..."
	: ../packages/$1
	PluginPackage.$1::download
}

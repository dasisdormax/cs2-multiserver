#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.warmod::download () {
	SourcemodHelper::downloadSmx \
		https://warmod.bitbucket.io/plugins/warmod.smx \
		286581d4fd87ed3d8c2a74836fc8d101f8126a39ccccb8984dcb275dbd7f2bcd
}

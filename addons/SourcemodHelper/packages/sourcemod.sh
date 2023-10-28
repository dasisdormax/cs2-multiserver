#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.sourcemod::download () {
	SourcemodHelper::unpackTar \
		https://sm.alliedmods.net/smdrop/1.11/sourcemod-1.11.0-git6924-linux.tar.gz \
		6936ef212c43d612d8b796774aa68b98a987c705e280bcfc1cc15bef467e7bd8
}

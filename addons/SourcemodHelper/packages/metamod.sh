#! /bin/bash
## vim: noet:sw=0:sts=0:ts=4

SourcemodPackage.metamod::download () {
	SourcemodHelper::unpackTar \
		https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1148-linux.tar.gz \
		187dc6ecc398c1df7b5c001442e5e44f9d3179aabce1738e24099b5907c36b2c
}

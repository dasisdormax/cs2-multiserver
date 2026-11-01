#! /bin/bash

SourcemodPackage.metamod::download () {
	SourcemodHelper::unpackTar \
		https://github.com/alliedmodders/metamod-source/releases/download/2.0.0.1483/mmsource-2.0.0-git1483-linux.tar.gz \
		0fdcccaa369937ed7f521c78462314b5266f39c1d65a84e4c2d3847324cd7776
}

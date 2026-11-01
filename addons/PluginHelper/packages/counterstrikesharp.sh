#! /bin/bash

PluginPackage.counterstrikesharp::download () {
	PluginHelper::unpackZip \
		https://github.com/roflmuffin/CounterStrikeSharp/releases/download/v1.0.379/counterstrikesharp-with-runtime-linux-1.0.379.zip \
		bd7e52265346a66a3106934c1f1085b642ec5560b7f070a9b10be510341d583a
}

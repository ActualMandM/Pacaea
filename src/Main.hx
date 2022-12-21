import haxe.Json;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import JsonFormat.Arc;
import JsonFormat.Entry;
import JsonFormat.Group;

using StringTools;

class Main
{
	static var groups:Array<String> = [
		"startup",
		"audio_init",
		"buttons",
		"mainmenu",
		"topbar",
		"base_shutters",
		"jackets_large",
		"jackets_small",
		"packs",
		"charts",
		"songselect_bgs",
		"character_sprites",
		"not_large_png",
		"not_large_jpg",
		"not_audio_or_images",
		"audio_wav",
		"not_audio",
		"Fallback"
	];

	static function main():Void
	{
		if (!FileSystem.exists("data"))
		{
			print("The data folder does not exist! Please create one and place your groups into it.");
			return;
		}
		else
		{
			packData();
		}
	}

	static function packData():Void
	{
		var json:Arc = { "Groups": [] };
		var pack:BytesBuffer = new BytesBuffer();

		print("Packing into arc.pack...");

		for (i in 0...groups.length)
		{
			var prevLengthGrp:Int = (i > 0) ? json.Groups[i - 1].Length : 0;
			var prevOffsetGrp:Int = (i > 0) ? json.Groups[i - 1].Offset : 0;

			var group:Group = {
				"Name": groups[i],
				"Offset": prevLengthGrp + prevOffsetGrp,
				"Length": 0,
				"OrderedEntries": []
			};

			if (!FileSystem.exists('data/${groups[i]}'))
			{
				json.Groups[i] = group;
				continue;
			}

			var folders:Array<String> = FileSystem.readDirectory('data/${groups[i]}');

			for (folder in folders)
			{
				var files:Array<String> = [];

				if (FileSystem.isDirectory('data/${groups[i]}/$folder'))
				{
					files = FileSystem.readDirectory('data/${groups[i]}/$folder');
				}
				else
				{
					createEntry(pack, group, i, 'data/${groups[i]}/$folder');
				}

				for (file in files)
				{
					if (FileSystem.isDirectory('data/${groups[i]}/$folder/$file'))
					{
						recursiveLoop(pack, group, i, 'data/${groups[i]}/$folder/$file');
						continue;
					}

					createEntry(pack, group, i, 'data/${groups[i]}/$folder/$file');
				}
			}

			json.Groups[i] = group;
		}

		File.saveContent("arc.json", Json.stringify(json, "  ").trim());
		File.saveBytes("arc.pack", pack.getBytes());
	}

	static function recursiveLoop(pack:BytesBuffer, group:Group, i:Int, directory:String):Void
	{
		if (FileSystem.exists(directory))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path = Path.join([directory, file]);
				if (!FileSystem.isDirectory(path))
				{
					createEntry(pack, group, i, path);
				}
				else
				{
					var directory = Path.addTrailingSlash(path);
					recursiveLoop(pack, group, i, directory);
				}
			}
		}
	}

	static function createEntry(pack:BytesBuffer, group:Group, i:Int, directory:String)
	{
		var length:Int = group.OrderedEntries.length;

		var data:Bytes = File.getBytes(directory);

		var prevLengthEnt:Int = (length > 0) ? group.OrderedEntries[length - 1].Length : 0;
		var prevOffsetEnt:Int = (length > 0) ? group.OrderedEntries[length - 1].Offset : 0 + group.Offset;

		var entry:Entry = {
			"OriginalFilename": directory.split('data/${groups[i]}/')[1],
			"Offset": prevLengthEnt + prevOffsetEnt,
			"Length": data.length
		};

		pack.add(data);
		group.Length += entry.Length;
		group.OrderedEntries[length] = entry;
	}

	inline static function print(text:String):Void
	{
		Sys.println(text);
	}
}

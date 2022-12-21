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

			var folders = FileSystem.readDirectory('data/${groups[i]}');

			for (folder in folders)
			{
				var files = FileSystem.readDirectory('data/${groups[i]}/$folder');

				var j:Int = 0;
				for (file in files)
				{
					if (FileSystem.isDirectory('data/${groups[i]}/$folder/$file'))
					{
						// recursivePack(group, 'data/${groups[i]}/$folder/$file');
						print('${groups[i]}/$folder/$file: Subfolders are currently unimplemented.');
						continue;
					}

					var data:Bytes = File.getBytes('data/${groups[i]}/$folder/$file');

					var prevLengthEnt:Int = (j > 0) ? group.OrderedEntries[j - 1].Length : 0;
					var prevOffsetEnt:Int = (j > 0) ? group.OrderedEntries[j - 1].Offset : 0 + group.Offset;

					var entry:Entry = {
						"OriginalFilename": '$folder/$file',
						"Offset": prevLengthEnt + prevOffsetEnt,
						"Length": data.length
					};

					pack.add(data);
					group.Length += entry.Length;
					group.OrderedEntries[j] = entry;

					j++;
				}
			}

			json.Groups[i] = group;
		}

		File.saveContent("arc.json", Json.stringify(json, "  ").trim());
		File.saveBytes("arc.pack", pack.getBytes());
	}

	static function recursiveLoop(directory:String):String
	{
		if (FileSystem.exists(directory))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path = Path.join([directory, file]);
				if (!FileSystem.isDirectory(path))
				{
					return path.substr(0, path.lastIndexOf("/"));
				}
				else
				{
					var directory = Path.addTrailingSlash(path);
					recursiveLoop(directory);
				}
			}

			return null;
		}
		else
		{
			return null;
		}
	}

	static function recursivePack(group:Group, directory:String):Void
	{
	}

	inline static function print(text:String):Void
	{
		Sys.println(text);
	}
}

typedef Arc = {
	var Groups:Array<Group>;
}

typedef Group = {
	var Name:String;
	var Offset:Int;
	var Length:Int;
	var OrderedEntries:Array<Entry>;
}

typedef Entry = {
	var OriginalFilename:String;
	var Offset:Int;
	var Length:Int;
}

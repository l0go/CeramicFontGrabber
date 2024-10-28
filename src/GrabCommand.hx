package;

import fuzzaldrin.Fuzzaldrin;

using StringTools;

class GrabCommand {
	inline static var API_URL = "https://gwfh.mranftl.com/api/fonts";

	public function new(options: Array<String>, values: Map<String, String>) {
		var client = new http.HttpClient();
		client.get(API_URL).then(r -> {
			var filtered = Fuzzaldrin.filter(r.bodyAsJson, values["family"], {key: "family", maxResults: 1});
			if (filtered.length <= 0) {
				Sys.println("Font family not found: " + values["family"]);
				Sys.exit(-1);
			}

			sys.FileSystem.createDirectory(".tmp");
			client.get(API_URL + '/${filtered[0].id}').then(r -> {
				for (variant in (r.bodyAsJson.variants : Array<Dynamic>)) {
					var family = (variant.fontFamily : String).replace(" ", "").replace("'", "");
					var fileName = '.tmp/${family}_${variant.fontWeight}_${styleFormat(variant.fontStyle)}.ttf';
					trace(variant.ttf);
					client.get(variant.tff).then(r -> {
						trace("Got bytes");
						sys.io.File.saveBytes(fileName, r.body);
						//final p = new sys.io.Process("ceramic", ["font", "--font", fileName, "--out", values["output"] ?? values["out"] ?? "assets/"]);
						//p.close();
					});
				}
			});
		});
    }

	static inline function styleFormat(style: String): String {
		return ~/(^| )./g.map(style, (m) -> m.matched(0).toUpperCase()).replace(" ", "_");
	}
}

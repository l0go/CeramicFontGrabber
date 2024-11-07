package;

import fuzzaldrin.Fuzzaldrin;
import promises.Promise;
import promises.PromiseUtils;

using StringTools;

typedef Font = {
	var glob: String;
	var fileName: String;
	var variant: {
		var fontFamily: String;
		var fontStyle: String;
		var fontWeight: String;
		var ttf: String;
	};
};

enum abstract FontWeight(String) {
	final THIN;
	final EXTRA_LIGHT;
	final LIGHT;
	final REGULAR;
	final MEDIUM;
	final SEMI_BOLD;
	final BOLD;
	final EXTRA_BOLD;
	final BLACK;
}

class GrabCommand {
	inline static final API_URL = "https://gwfh.mranftl.com/api/fonts";
	static final fontWeights = [
		100 => FontWeight.THIN,
		200 => FontWeight.EXTRA_LIGHT,
		300 => FontWeight.LIGHT,
		400 => FontWeight.REGULAR,
		500 => FontWeight.MEDIUM,
		600 => FontWeight.SEMI_BOLD,
		700 => FontWeight.BOLD,
		800 => FontWeight.EXTRA_BOLD,
		900 => FontWeight.BLACK,
	];

	public function new(options: Array<String>, values: Map<String, String>) {
		var client = new http.HttpClient();
		var fonts: Array<Font> = [];

		log('Requesting font list from $API_URL');
		client.get(API_URL).then(r -> {
			log("Recieved font list, now searching font families");
			var filtered = Fuzzaldrin.filter(r.bodyAsJson, values["family"], {key: "family", maxResults: 1});
			if (filtered.length <= 0) {
				log("Font family not found: " + values["family"]);
				Sys.exit(-1);
			}
			sys.FileSystem.createDirectory(".tmp-fonts");
			return client.get(API_URL + '/${filtered[0].id}');
		}).then(r -> {
			log('Font family found');
			var promises = [];
			for (variant in (r.bodyAsJson.variants : Array<Dynamic>)) {
				final family = (variant.fontFamily : String).replace(" ", "").replace("'", "");
				final glob = '${family}_${variant.fontWeight}_${styleFormat(variant.fontStyle)}';
				final font: Font = {
					glob: glob,
					fileName: glob + ".ttf",
					variant: variant
				};
				fonts.push(font);
				log('Downloading: ${font.fileName}');
				promises.push(saveFont.bind(client, font));
			}
			return PromiseUtils.runAll(promises);
		}).then(_ -> {
			log("Generating msdf fonts");
			sys.FileSystem.createDirectory(values["output"] ?? "assets/");
			for (f in fonts) {
				var p = new sys.io.Process("ceramic", ["font", "--font", '.tmp-fonts/${f.fileName}', "--msdf", "--out", values["output"] ?? "assets/"]);
				if (p.exitCode() != 0) {
					throw p.stderr.readAll().toString();
				}
				p.close();
			}
		}).then(_ -> {
			if (!options.contains("haxeui-options")) return;
			var buf = new StringBuf();
			buf.add("font_weights: [\n");
			var italics: Array<Font> = [];
			for (f in fonts) {
				if (f.variant.fontStyle.toUpperCase() == "ITALIC") {
					italics.push(f);
					continue;
				}
				buf.add("\t");
				buf.add('${fontWeights[Std.parseInt(f.variant.fontWeight)]} => app.assets.font(Fonts.${f.glob.toUpperCase()}),\n');
			}
			buf.add("]");
			if (italics.length > 0) {
				buf.add("\nfont_italics: [\n");
				for (f in italics) {
					buf.add("\t");
					buf.add('${fontWeights[Std.parseInt(f.variant.fontWeight)]} => app.assets.font(Fonts.${f.glob.toUpperCase()}),\n');
				}
				buf.add("]");
			}
			Sys.println(buf.toString());
		}).then(_ -> {
			recursiveDeleteDirectory(".tmp-fonts");
			log("All done!");
		}, error -> {
			log('ono, there was an error: $error');
		});
	}

	function saveFont(client: http.HttpClient, font: Font): Promise<Bool> {
		return new Promise((resolve, reject) -> {
			client.get((font.variant.ttf : String)).then(r -> {
				try {
					sys.io.File.saveBytes('.tmp-fonts/${font.fileName}', r.body);
					log('Font saved: ${font.fileName} (${r.body.length})');
				} catch (e) {
					reject(e);
				}
				resolve(true);
			}, error -> {
				reject(error);
			});
		});
	}

	inline function log(str: String) {
		Sys.stderr().writeString('$str\n');
	}

	static inline function styleFormat(style: String): String {
		return ~/(^| )./g.map(style, (m) -> m.matched(0).toUpperCase()).replace(" ", "_");
	}
	
	static function recursiveDeleteDirectory(path: String) {
		if (sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path)) {
			var entries = sys.FileSystem.readDirectory(path);
			for (entry in entries) {
				if (sys.FileSystem.isDirectory(path + '/' + entry)) {
					recursiveDeleteDirectory(path + '/' + entry);
					sys.FileSystem.deleteDirectory(path + '/' + entry);
				} else {
					sys.FileSystem.deleteFile(path + '/' + entry);
				}
			}
		}
	}
}

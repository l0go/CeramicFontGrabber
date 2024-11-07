package;

using StringTools;

enum Tokens {
	ValueFlag(name: String, content: String);
	OptionFlag(name: String);
}

typedef Command = {
	constructor: (options: Array<String>, values: Map<String, String>) -> Void,
	description: String,
	usage: String,
};

class Main {
	static var commands: Map<String, Command> = [
		"grab" => {
			constructor: GrabCommand.new,
			description: "Downloads the given Google Font family and generates msdf fonts",
			usage: 'grab --family "Open Sans" --haxeui-options --output assets/',
		},
	];

	static function main() {
		final args = Sys.args();

		// Incredibly basic arg parser, but it does the job
		var i = 0;
		final command = args[i++]?.toLowerCase();
		if (command == "--help") {
			help();
			Sys.exit(0);
		} else if (command == null || !commands.exists(command)) {
			if (command != null) {
				Sys.println("command not found: " + command);
			}
			help();
			Sys.exit(-1);
		}

		final tokens = [while (args.length > i) {
			if (args[i].startsWith("--") && !(args[i + 1] ?? "--").startsWith("--")) {
				ValueFlag(args[i].substr(2).toLowerCase(), args[++i]);
			} else if (args[i].startsWith("--")) {
				OptionFlag(args[i++].substr(2).toLowerCase());
			} else {
				i++;
				continue;
			}
		}];
	
		final values = new Map<String, String>();
		final options: Array<String> = [];
		for (token in tokens) switch (token) {
			case ValueFlag(name, content):
				values[name] = content;
			case OptionFlag(name):
				options.push(name);
		}

		commands[command].constructor(options, values);
	}

	static function help() {
		Sys.println("Help for CeramicFontGrabber");
		for (name => command in commands) {
			Sys.println('$name: ${command.description}');
			Sys.println('\tEXAMPLE USAGE: ${command.usage}');
		}
	}
}

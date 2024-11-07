# CeramicFontGrabber
A little tool that downloads and converts Google Fonts to a format accepted by [https://ceramic-engine.com/](Ceramic Engine). Additionally it will generate the ``font_weights`` and ``font_italics`` options for [https://github.com/Jarrio/haxeui-ceramic/](haxeui-ceramic).

## Requirements
- Haxe (Tested on version 4.3.4)
- Hashlink (Any other sys target *should* work, just modify ``build.hxml``)
- Ceramic (Make sure it is on your path, i.e ``ceramic`` is a valid command.)

## Usage
1. Clone this repository and its submodules
```
git clone --recurse-submodules -j8 https://github.com/l0go/CeramicFontGrabber && cd CeramicFontGrabber
```
2. Compile CeramicFontGrabber
```
haxe build.hxml
```
3. For a simple test, you can try this command. It will download Open Sans from Google Fonts and spit out the bitmap fonts generated by Ceramic in ``assets/``
```
hl grabber.hl grab --family "Open Sans"
```
If you want to additionally generate the configuration options required by haxeui-ceramic, add the ``--haxeui-options`` flag like so
```
hl grabber.hl grab --family "Open Sans" --haxeui-options
```

## License
This project is released under the permissive zlib license. See ``LICENSE`` for more details.
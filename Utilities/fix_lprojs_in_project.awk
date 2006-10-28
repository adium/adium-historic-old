function replace_all_languages() {
	gsub(/Afrikaans/,	"af");
	gsub(/Albanian/,	"sq");
	gsub(/Amharic/,	"am");
	gsub(/Arabic/,	"ar");
	gsub(/Armenian/,	"hy");
	gsub(/Assamese/,	"as");
	gsub(/Aymara/,	"ay");
	gsub(/Azerbaijani/,	"az");
	gsub(/Basque/,	"eu");
	gsub(/Bengali/,	"bn");
	gsub(/Breton/,	"br");
	gsub(/Bulgarian/,	"bg");
	gsub(/Burmese/,	"my");
	gsub(/Byelorussian/,	"be");
	gsub(/Catalan/,	"ca");
	gsub(/"?Traditional Chinese"?/,	"zh_TW");
	gsub(/"?Simplified Chinese"?/,	"zh_CN");
	gsub(/Chinese/,	"zh");
	gsub(/Croatian/,	"hr");
	gsub(/Czech/,	"cs");
	gsub(/Danish/,	"da");
	gsub(/Dutch/,	"nl");
	gsub(/Dzongkha/,	"dz");
	gsub(/English/,	"en");
	gsub(/Esperanto/,	"eo");
	gsub(/Estonian/,	"et");
	gsub(/Faroese/,	"fo");
	gsub(/Farsi/,	"fa");
	gsub(/Finnish/,	"fi");
	gsub(/French/,	"fr");
	gsub(/Galician/,	"gl");
	gsub(/Georgian/,	"ka");
	gsub(/German/,	"de");
	gsub(/Greek/,	"el");
	gsub(/Greenlandic/,	"kl");
	gsub(/Guarani/,	"gn");
	gsub(/Gujarati/,	"gu");
	gsub(/Hebrew/,	"he");
	gsub(/Hindi/,	"hi");
	gsub(/Hungarian/,	"hu");
	gsub(/Icelandic/,	"is");
	gsub(/Indonesian/,	"id");
	gsub(/Inuktitut/,	"iu");
	gsub(/Irish/,	"ga");
	gsub(/Italian/,	"it");
	gsub(/Japanese/,	"ja");
	gsub(/Javanese/,	"jv");
	gsub(/Kannada/,	"kn");
	gsub(/Kashmiri/,	"ks");
	gsub(/Kazakh/,	"kk");
	gsub(/Khmer/,	"km");
	gsub(/Kinyarwanda/,	"rw");
	gsub(/Kirghiz/,	"ky");
	gsub(/Korean/,	"ko");
	gsub(/Kurdish/,	"ku");
	gsub(/Lao/,	"lo");
	gsub(/Latin/,	"la");
	gsub(/Latvian/,	"lv");
	gsub(/Lithuanian/,	"lt");
	gsub(/Macedonian/,	"mk");
	gsub(/Malagasy/,	"mg");
	gsub(/Malay/,	"ms");
	gsub(/Malayalam/,	"ml");
	gsub(/Maltese/,	"mt");
	gsub(/Manx/,	"gv");
	gsub(/Marathi/,	"mr");
	gsub(/Moldavian/,	"mo");
	gsub(/Mongolian/,	"mn");
	gsub(/Nepali/,	"ne");
	gsub(/Norwegian/,	"nb");
	gsub(/Nyanja/,	"ny");
	gsub(/Nynorsk/,	"nn");
	gsub(/Oriya/,	"or");
	gsub(/Oromo/,	"om");
	gsub(/Pashto/,	"ps");
	gsub(/Polish/,	"pl");
	gsub(/Portuguese/,	"pt");
	gsub(/Punjabi/,	"pa");
	gsub(/Quechua/,	"qu");
	gsub(/Romanian/,	"ro");
	gsub(/Rundi/,	"rn");
	gsub(/Russian/,	"ru");
	gsub(/Sami/,	"se");
	gsub(/Sanskrit/,	"sa");
	gsub(/Scottish/,	"gd");
	gsub(/Serbian/,	"sr");
	gsub(/Sindhi/,	"sd");
	gsub(/Sinhalese/,	"si");
	gsub(/Slovak/,	"sk");
	gsub(/Slovenian/,	"sl");
	gsub(/Somali/,	"so");
	gsub(/Spanish/,	"es");
	gsub(/Sundanese/,	"su");
	gsub(/Swahili/,	"sw");
	gsub(/Swedish/,	"sv");
	gsub(/Tagalog/,	"tl");
	gsub(/Tajiki/,	"tg");
	gsub(/Tamil/,	"ta");
	gsub(/Tatar/,	"tt");
	gsub(/Telugu/,	"te");
	gsub(/Thai/,	"th");
	gsub(/Tibetan/,	"bo");
	gsub(/Tigrinya/,	"ti");
	gsub(/Tongan/,	"to");
	gsub(/Turkish/,	"tr");
	gsub(/Turkmen/,	"tk");
	gsub(/Uighur/,	"ug");
	gsub(/Ukrainian/,	"uk");
	gsub(/Urdu/,	"ur");
	gsub(/Uzbek/,	"uz");
	gsub(/Vietnamese/,	"vi");
	gsub(/Welsh/,	"cy");
	gsub(/Yiddish/,	"yi");
}
/isa = PBXFileReference/ {
	replace_all_languages();
}
# Item in a “Known regions” list.
/^\t+([A-Za-z_]+|"[A-Za-z _]*"),$/ {
	replace_all_languages();
}
# Object reference in a PBXVariantGroup.
/^\t+[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F] \/\* [A-Za-z_]+ \*\/,$/ {
	replace_all_languages();
}

{
	print;
}

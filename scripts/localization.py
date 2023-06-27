#!/usr/bin/env python

import glob
import os
import sys
import optparse

arguments = sys.argv[1:]

parser = optparse.OptionParser()
parser.add_option("--import", action="store_true", dest="import", help="Import localization from xliff files")
parser.add_option("--export", action="store_true", dest="export", help="Export localization to xliff files")

(options, args) = parser.parse_args(arguments)
options = vars(options)

abspath = os.path.abspath(__file__)
basepath = os.path.dirname(abspath)

projects = {
    "DocumentsApp": {
        "project": "../Documents/Documents.xcodeproj",
        "localizations": "../Documents/Localization"
    },
}

support_langs = ["bg", "cs", "de", "en", "es", "fr", "hy-AM", "it", "ja", "pt-BR", "ru", "si", "zh-Hans", "zh-Hant"]

def import_localization():
    for key, value in projects.items():
        print("Import localization for {}".format(key))
        os.chdir(basepath)
        project = os.path.abspath(value["project"])
        os.chdir(value["localizations"])
        for xliff in glob.glob("*.xliff"):
            print("Importing {} ".format(os.path.splitext(os.path.basename(xliff))[0]))
            os.system("xcodebuild -importLocalizations -project {0} -localizationPath {1}".format(project, xliff))
        print("")

def export_localization():
    for key, value in projects.items():
        print("Export localization for {}".format(key))
        os.chdir(basepath)
        project = os.path.abspath(value["project"])
        localizations = os.path.abspath(value["localizations"])
        for lang in support_langs:
            os.system("xcodebuild -exportLocalizations -project {0} -localizationPath {1} -exportLanguage {2}".format(project, localizations, lang))
            xcloc = "{0}/{1}.xcloc".format(localizations, lang)
            xliff = "{0}/Localized Contents/{1}.xliff".format(xcloc, lang)
            if os.path.exists(xcloc) and os.path.exists(xliff):
                os.system('rsync -a --delete "{0}" "{1}"'.format(xliff, localizations))
                os.system('rm -r "{0}"'.format(xcloc))
        print("")


if options["import"]:
    import_localization()
elif options["export"]:
    export_localization()
else:
    import_localization()
    export_localization()

package util;

import haxe.io.Path;
import Sys.println as log;
import util.U;

using StringTools;

typedef HaxeVersion = { ver:String, major:Int, minor:Int, patch:Int };
typedef HaxelibVer = { name:String, ver:String, major:Int, minor:Int, patch:Int, path:String };
typedef Haxelib = { versions:Map<String, HaxelibVer>, name:String, path:String };

class Haxe {

    public static var version : HaxeVersion;
    public static var haxelib_path : String;
    public static var libs : Map<String, Haxelib> = new Map();
    
//public api

    public static function lib(name:String) : Haxelib {
        if(!libs.exists(name)) return null;
        return libs.get(name);
    }

    public static function lib_current(name:String) : HaxelibVer {
        if(!libs.exists(name)) return null;
        var _lib = libs.get(name);
        return _lib.versions.get('*');
    }

    public static function lib_at(name:String, ver:String) : HaxelibVer {
        if(!libs.exists(name)) return null;
        var _lib = libs.get(name);
        return _lib.versions.get(ver);
    }

    public static function lib_compare(a:HaxelibVer, b:HaxelibVer) : Int {

        var need_update = false;
        if(a.major == b.major && a.minor == b.minor && a.patch == b.patch) return 0;

        var lmajor = a.major < b.major;
        var lminor = a.minor < b.minor;
        var lpatch = a.patch < b.patch;

        if(lmajor) return -1;
        if(!lmajor && lminor) return -1;
        if(!lmajor && !lminor && lpatch) return -1;

        return 1;

    } //lib_compare

    public static function lib_latest(name:String) : HaxelibVer {

        var result = U.run('haxelib',['info', name]);
        if(result.code != 0) return null;

        var r = ~/\bVersion: ((\d+).(\d+).(\d+)(.+)*)\b/;
            r.match(result.out);

        var ver = r.matched(1);
        var major = Std.parseInt(r.matched(2));
        var minor = Std.parseInt(r.matched(3));
        var patch = Std.parseInt(r.matched(4));

        return { name:name, ver:ver, major:major, minor:minor, patch:patch, path:'lib.haxe.org' };

    } //lib_latest

//internal
    
    @:allow(M)
    static function init() {
        init_haxe();
        init_haxelib();
    }

    static function init_haxe() {

        // log('haxe - init');

            //:todo: haxe path from config
        var result = U.run('haxe',['-version']);

        if(result.code == 1) {
            var _err = '\n\nHaxe is required and can\'t be found.\n\n';
                _err += ' > Do you have Haxe installed?\n';
                _err += ' > ${result.err.trim()}\n';
            throw _err;
        }

        var detail = result.err.trim();
        var parts = detail.split('.');

        version = {
            ver:   detail,
            major: Std.parseInt(parts[0]),
            minor: Std.parseInt(parts[1]),
            patch: Std.parseInt(parts[2])
        };

    } //init_haxe

    static var unparsed_versions : Map<String, String> = new Map();
    static function init_haxelib() {

        // log('haxelib - init');

            //:todo: haxelib binary path from config
        var result = U.run('haxelib',['config']);

            // :todo:better error handling
        if(result.code == 1) {
            var _err = '\n\nHaxe is required and can\'t be found.\n\n';
                _err += ' > Do you have Haxe installed?\n';
                _err += ' > ${result.err.trim()}\n';
            throw _err;
        }

        haxelib_path = U.normalize(result.out.trim());

        var res = U.run('haxelib', ['list']);
        var list_raw = StringTools.trim(res.out);
        var list = list_raw.split('\n');

        var re = ~/^([.0-9a-zA-Z-_]*)(:{1})\s(.*)$/igm;
        for(lib in list) {
            var match = re.match(lib);
            if(match) {
                var name = re.matched(1);
                var ver = re.matched(3);
                libs.set(name, { name:name, versions:new Map(), path:'' });
                unparsed_versions.set(name, ver);
            } else {
                // log('haxelib - init - no match for haxelib name/version regex for $lib?');
            }
        }

        parse_haxelib_versions();

    } //init_haxelib

    static function parse_haxelib_versions() {

        for(lib in libs) {
            // log('parsing ${lib.name}');

            var _current = false;
            var _unparsed = unparsed_versions.get(lib.name);
            var _vers = _unparsed.split(' ');
                _vers = _vers.map(function(s) return s.trim() );

            for(_ver in _vers) {

                _current = _ver.indexOf('[') != -1;
                _ver = _ver.replace('[','');
                _ver = _ver.replace(']','');

                // log('   $_ver / current:$_current');

                var _lib_path = '';
                var _lib_base = Path.join([haxelib_path, lib.name]);

                if(_ver.substr(0,4) == 'dev:') {
                    _lib_path = _ver.replace('dev:','');
                    _ver = 'dev';
                } else if(_ver == 'git') {
                    _lib_path = Path.join([ _lib_base, 'git' ]);
                } else {
                    _lib_path = Path.join([ _lib_base, _ver.replace('.',',') ]);
                }

                _lib_path = U.normalize(_lib_path);

                var _parts = _ver.split('.');

                var _haxelib_ver = { 
                    ver: _ver, 
                    major: Std.parseInt(_parts[0]), 
                    minor: Std.parseInt(_parts[1]), 
                    patch: Std.parseInt(_parts[2]), 
                    path:_lib_path, 
                    name:lib.name 
                };
                if(_current) lib.versions.set('*', _haxelib_ver);
                lib.versions.set(_ver, _haxelib_ver);
                lib.path = U.normalize(_lib_base);

                // log(lib);

            } //each ver

        } //each lib

    } //parse_haxelib_versions

} //Haxe

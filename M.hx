import Sys.println as log;
import util.Haxe;
import util.U;
import haxe.io.Path;
using StringTools;

class M {

    function new() {}
    public static var i: M = new M();
    static function main() i.init();

    var online = true;
    var config : Dynamic;

    function init() {

        var str = sys.io.File.getContent('./haxelib.json');
        if(str == null || str == '') { log('haxelib.json can\'t be found for snowfall, is the cwd correct?'); return; }
        var json = haxe.Json.parse(str);

        str = sys.io.File.getContent('./config.json');
        if(str == null || str == '') { log('config.json can\'t be found for snowfall, is the cwd correct?'); return; }
        config = haxe.Json.parse(str);

        log('snowfall ' + json.version);

        Haxe.init();

        online = check_lib_update('snowfall');
        if(online) check_lib_update('hxcpp');
        check_args();

    } //main

    function check_lib_update(name:String) : Bool {
        var cur = Haxe.lib_current(name);
        var lat = Haxe.lib_latest(name);
        if(lat != null && lat != null) {
            if(Haxe.lib_compare(cur, lat) < 0) {
                log('\n> $name ${lat.ver} is available, your $name version is set to ${cur.ver}');
            }
        }
        return lat != null;
    }

    function check_args() {

        var args = arguable.ArgParser.parse(Sys.args());

        if(args.invalid.length <= 1) {
            log('\n> A temporary convenience for luxe & snow during active dev\n');
            return help();
        }

        var action = args.invalid[0];
        var lib = args.invalid.length > 1 ? args.invalid[1] : null;

        log('\n> haxe - version - ${Haxe.version.ver}');
        log('> haxelib - path - ${Haxe.haxelib_path}\n');

        if(['shortcuts','update'].indexOf(action.name) == -1) {
            log('\n> unknown option `${action.name}`\n');
            return help();
        }

        if(action.name == 'update' && ['snow','luxe'].indexOf(lib.name) == -1) {
            log('\n> unknown lib `${lib.name}` - use haxelib instead\n');
            return help();
        }

        if(action.name == 'shortcuts') {
            shortcuts();
        } else {
            if(online) {
                update(lib.name);
            } else {
                log('\nUH OH');
                log('\n> You appear to be offline, can\'t update!');
            }
        }

    } //check_args

    function url_for(name:String) {
        return switch(name) {
            case 'flow':            'https://github.com/underscorediscovery/flow.git';
            case 'snow':            'https://github.com/underscorediscovery/snow.git';
            case 'luxe':            'https://github.com/underscorediscovery/luxe.git';
            case 'linc_openal':     'https://github.com/snowkit/linc_openal.git';
            case 'linc_timestamp':  'https://github.com/snowkit/linc_timestamp.git';
            case 'linc_stb':        'https://github.com/snowkit/linc_stb.git';
            case 'linc_ogg':        'https://github.com/snowkit/linc_ogg.git';
            case 'linc_sdl':        'https://github.com/snowkit/linc_sdl.git';
            case 'linc_opengl':     'https://github.com/snowkit/linc_opengl.git';
            case 'linc_rtmidi':     'https://github.com/KeyMaster-/linc_rtmidi.git';
            case _: throw "unknown lib" + name;
        }
    }

    function ualias(name:String, path:String) {
        try {
            sys.io.File.saveContent(path, '#!/bin/sh\nhaxelib run $name "$@"\n');
            log('> $name alias written to $path');
            var res = U.run('chmod', ['+x', '$path']);
            if(res.code != 0) throw 'The following command failed: chmod +x $path';
            res = U.run('chmod', ['755', '$path']);
            if(res.code != 0) throw 'The following command failed: chmod 755 $path';
        } catch(e:Dynamic) {
            log('> error when writing to $path!');
            log('> you might need to use `sudo haxelib run snowfall shortcuts`');
            log('> ' + e);
            return false;
        }
        return true;
    }

    function walias(name:String, path:String) {
        try {
            sys.io.File.saveContent(path, '@echo off\nhaxelib run $name %*\n');
            log('> $name alias written to $path');
        } catch(e:Dynamic) {
            log('> error when writing to $path!');
            log('> you might need to manually install the shortcuts.');
            log('> ' + e);
            return false;
        }
        return true;
    }

    function shortcuts() {
        
        var os = Std.string(Sys.systemName()).toLowerCase();
        var us = Haxe.lib_current('snowfall');
        var config_path = U.normalize(Path.join([us.path,'config.json']));

        log('\n> Installing shortcuts for `flow` and `snowfall` on $os');

        switch(os) {
            case 'windows':
                var dest = config.shortcuts.windows;
                if(dest != null && dest != "") {
                    if(!sys.FileSystem.exists(dest)) {
                        log('\n> error: $dest doesn\'t exist!');
                        log('> you should edit $config_path to correct the path');
                        log('> or install the shortcuts manually.');
                    } else {
                        var flow_path = U.normalize(Path.join([dest, 'flow.bat']));
                        var snowfall_path = U.normalize(Path.join([dest, 'snowfall.bat']));
                        var ok = walias('flow', flow_path);
                        if(ok) ok = walias('snowfall', snowfall_path);
                        if(!ok) log('> can\'t continue');
                        if(ok) {
                            log('\n> You should be to run flow and snowfall without the haxelib run prefix now');
                            log('> done.');
                        }
                    }
                }
            case 'linux','mac':
                var dest = os == 'linux' ? config.shortcuts.linux : config.shortcuts.mac;
                if(dest != null && dest != "") {
                    var flow_path = U.normalize(Path.join([dest, 'flow']));
                    var snowfall_path = U.normalize(Path.join([dest, 'snowfall']));
                    var ok = ualias('flow', flow_path);
                    if(ok) ok = ualias('snowfall', snowfall_path);
                    if(!ok) log('> can\'t continue');
                    if(ok) {
                        log('\n> You should be to run flow and snowfall without the haxelib run prefix now');
                        log('> done.');
                    }
                }
            case '_': throw "unknown platform: " + os;
        }

    } //shortcuts

    function update(name:String) {

        var list = ['flow'];

        if(name == 'snow' || name == 'luxe') {
            list = list.concat([
                'linc_openal',
                'linc_timestamp',
                'linc_stb',
                'linc_ogg',
                'linc_sdl',
                'linc_opengl',
                'snow',
            ]);
        }

        if(name == 'luxe') {
            list.push('luxe');
        }

        log('> requesting updates for $name...');

        for(lib in list) {
            var found = Haxe.lib(lib);
            if(found == null) {

                var lib_path = U.normalize(Path.join([Haxe.haxelib_path, lib, 'git']));
                var lib_url = url_for(lib);

                log('> installing $lib - git clone $lib_url to <haxelib>${lib_path.replace(Haxe.haxelib_path,"")}\n');
                U.run('git',['clone', '--progress', lib_url, lib_path], true);
                U.run('haxelib', ['dev', lib, lib_path], true);

            } else {
                log('> updating $lib');
                var cur = Haxe.lib_current(lib);
                if(cur.ver == 'dev') {
                    var git_path = U.normalize(Path.join([cur.path,'.git']));
                    if(sys.FileSystem.exists(git_path)) {
                        U.run('git', ['pull', '--progress'], cur.path, true);
                    } else {
                        log('> Error - !! - cannot update dev version of a library, only git based versions');
                    }
                } else {
                    log(' !! currently only git or dev based haxelib installs of $lib are supported by snowfall');
                }
            }
        }

        log('\n> done.');

    }

    function help() {

        log('options\n');
        log('> update [lib]   |  update or install a lib (snow or luxe)');
        log('> shortcuts      |  install "flow" & "snowfall" command line shortcuts');
        log('\nnotes\n');
        log('> All dependencies of [lib] will be installed or updated.');
        log('> i.e `snowfall update luxe` will update snow, and flow.\n');

    } //help

} //M

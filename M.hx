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

    function init() {

        var str = sys.io.File.getContent('./haxelib.json');
        if(str == null || str == '') { log('haxelib.json can\'t be found for snowfall, is the cwd correct?'); return; }
        var json = haxe.Json.parse(str);

        log('snowfall ' + json.version);

        Haxe.init();

        online = check_lib_update('snowfall');
        check_args();

    } //main

    function check_lib_update(name:String) : Bool {
        
        var cur = Haxe.lib_current(name);
        var lat = Haxe.lib_latest(name);

        if(cur == null) {
            log('> $name is not installed. You can run `haxelib install $name` if you need it.');
        } else if(lat != null) {
            if(Haxe.lib_compare(cur, lat) < 0) {
                log('> $name ${lat.ver} is available, your $name version is set to ${cur.ver}.\n  - You can run `haxelib update $name` to update.');
            }
        }

        return lat != null;

    } //

    function check_args() {

        var sys_args = Sys.args(); 
            sys_args.pop();
        var args = arguable.ArgParser.parse(sys_args);

        if(args.invalid.length == 0) {
            log('\n> A temporary convenience for luxe & snow during active dev\n');
            return help();
        }

        var action = args.invalid[0];
        var lib = args.invalid.length > 1 ? args.invalid[1] : null;

    //immediate actions

        if(action.name == 'news') {
            return news(lib != null ? lib.name : null);
        }

        log('\n> haxe - version - ${Haxe.version.ver}');
        log('> haxelib - path - ${Haxe.haxelib_path}\n');

        if(online) check_lib_update('hxcpp');

    //validation

        if(['shortcuts','update','status','news','test'].indexOf(action.name) == -1) {
            log('\n> unknown option `${action.name}`\n');
            return help();
        }

        if(action.name == 'update' || action.name == 'status') { 
            var libs = ['snow','luxe'];

            if(!(lib != null && lib.name != '')) {
                log('\n> the ${action.name} command requires a lib name, one of: `${libs.join(", ")}`\n');
                return help();
            }
            
            if(libs.indexOf(lib.name) == -1) {
                log('\n> unknown lib `${lib.name}` - use haxelib instead.\n> Only `${libs.join(", ")}` can be updated this way.\n');
                return help();
            }
        }

    //actions

        if(action.name == 'shortcuts') {
            var path = '';
            if(lib != null) path = lib.name;
            shortcuts(path);
        } else if(action.name == 'status') {
            if(require_online()) {
                status(lib.name);
            }
        } else if(action.name == 'update') {
            if(require_online()) {
                update(lib.name);
            }
        } else if(action.name == 'test') {
            if(lib != null) {
                if(lib.name != 'snow' && lib.name != 'luxe') {
                    log('\nCan only test `luxe` or `snow`');
                } else {
                    test(lib.name);
                }
            } else {
                log('\ntest requires a lib argument, try `snowfall test luxe`');
            }
        }

    } //check_args

    function require_online() {
        
        if(online) return true;

        log('\nUH OH');
        log('\n> You appear to be offline, can\'t proceed!');

        return false;

    } //require_online

        //:todo: There's a whole lot of stuff to add here, 
        //but blocking it in for now
    function news(dest:String) {

        var url = switch(dest) {
            case 'snowkit': 'http://snowkit.org/tag/snowkitdev/';
            case _: 'http://luxeengine.com/tag/update/';
        }

        log('> fetching news...');
        log('> viewable at $url\n');

        var posts = U.rss('${url}rss/');
        for(post in posts) log('  ${post.posted}  |  ${post.title} ');

        log('');

    } //news

    function test(lib:String) {

        var found = Haxe.lib(lib);
        if(found == null) {
                //lib is not installed
            log('> cannot test $lib, it is not installed!\n');
            log('> you can use the update command to install missing libraries');
            log('> try `snowfall update $lib` before running test');
        } else {
                //installed
            Sys.print('\n> Testing $lib has been setup ... ');
            Sys.print('\n> ()note this runs a web target build, native targets differ!)');

            var cur = Haxe.lib_current(lib);
            var sample_path = switch(lib) {
                case 'luxe': 'tests/features/draw/';
                case 'snow': 'samples/basic/';
                case _: return;
            }
            
            var test_path = U.normalize(Path.join([cur.path,sample_path]));
            if(sys.FileSystem.exists(test_path)) {
                log('\n> Running the test sample at `$test_path`');
                log('\n> Your browser should open the link shortly!');
                U.run('haxelib', ['run', 'flow', 'run', 'web', '--timeout', '4', '--project-root', test_path]);
            } else {
                log('\nerror: can\'t find test path where expected at: `$test_path`');
                log('can\'t continue attempt to test.');
            }

        }

    } //test

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

    function shortcuts(config_path:String) {

        var os = Std.string(Sys.systemName()).toLowerCase();
        var us = Haxe.lib_current('snowfall');

        log('\n> Installing shortcuts for `flow` and `snowfall` on $os');
        if(config_path != '') {
            log('> Using requested path: $config_path\n');
        } else {
            config_path = os == 'windows' ? 'C:/HaxeToolkit/haxe/' : '/usr/local/bin/';
            log('> No path specified, default path is $config_path');
            log('> You can enter a different one, or hit enter to use the default:');
            var inval = Sys.stdin().readLine();
            if(inval != '') {
                config_path = inval;
            }
        }

        log('> checking $config_path');
        if(!sys.FileSystem.exists(config_path)) {
            log('\n> error: $config_path doesn\'t exist!');
            log('> you should give a valid location in your PATH,');
            log('> or install the shortcuts manually.');
            return;
        }

        switch(os) {
            case 'windows':
                var flow_path = U.normalize(Path.join([config_path, 'flow.bat']));
                var snowfall_path = U.normalize(Path.join([config_path, 'snowfall.bat']));
                var ok = walias('flow', flow_path);
                if(ok) ok = walias('snowfall', snowfall_path);
                if(!ok) log('> can\'t continue');
                if(ok) {
                    log('\n> You should be to run flow and snowfall without the haxelib run prefix now');
                    log('> done.');
                }
            case 'linux','mac':
                var flow_path = U.normalize(Path.join([config_path, 'flow']));
                var snowfall_path = U.normalize(Path.join([config_path, 'snowfall']));
                var ok = ualias('flow', flow_path);
                if(ok) ok = ualias('snowfall', snowfall_path);
                if(!ok) log('> can\'t continue');
                if(ok) {
                    log('\n> You should be to run flow and snowfall without the haxelib run prefix now');
                    log('> done.');
                }
            case '_': throw "unknown platform: " + os;
        }

    } //shortcuts

    function list_git_deps(lib:String) {
        
        var list = ['flow'];

        if(lib == 'snow' || lib == 'luxe') {
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

        if(lib == 'luxe') {
            list.push('luxe');
        }

        return list;

    } //list_git_deps

    function status(name:String) {

        var list = list_git_deps(name);
        for(lib in list) {
            var found = Haxe.lib(lib);
            if(found == null) {
                //lib is not installed
                log('> cannot check the status of $name, it is not installed!\n');
                log('> you can use the update command to install missing libraries');
            } else {
                //installed,
                Sys.print('> $lib ... ');
                var cur = Haxe.lib_current(lib);
                if(cur.ver == 'dev') {
                    var git_path = U.normalize(Path.join([cur.path,'.git']));
                    if(sys.FileSystem.exists(git_path)) {
                        #if debug log('> check $lib - `git rev-list HEAD...origin/master --count` - run at ${cur.path}\n'); #end
                        var pre = Sys.getCwd();
                        Sys.setCwd(cur.path);
                        U.run('git', ['fetch']);
                        var o = U.run('git', ['rev-list','HEAD...origin/master','--count']);
                        var count = -1;
                        if(o.code == 0 && o.out != '') count = Std.parseInt(o.out.trim());
                        if(count >= 0) {
                            log('$count ${count == 1 ? "update" : "updates"}');
                            if(count > 0) {
                                log('');
                                Sys.command('git', ['log', 'HEAD..origin/master', '--oneline']);
                            }
                        }
                        Sys.setCwd(pre);
                    } else {
                        log('> Error - !! - cannot update dev version of a library, only git based versions');
                    }
                } else {
                    log(' !! currently only git or dev based haxelib installs of $lib are supported by snowfall');
                }
            }
        }//each
        log('');

    } //

    function update(name:String) {

        var list = list_git_deps(name);

        log('> requesting updates for $name...');

        for(lib in list) {
            var found = Haxe.lib(lib);
            if(found == null) {

                var lib_path = U.normalize(Path.join([Haxe.haxelib_path, lib, 'git']));
                var lib_url = url_for(lib);

                log('> installing $lib - git clone $lib_url to <haxelib>${lib_path.replace(Haxe.haxelib_path,"")}\n');
                Sys.command('git',['clone', '--progress', '--recursive', lib_url, lib_path]);
                U.run('haxelib', ['dev', lib, lib_path], true);

            } else {
                log('> updating $lib');
                var cur = Haxe.lib_current(lib);
                if(cur.ver == 'dev') {
                    var git_path = U.normalize(Path.join([cur.path,'.git']));
                    if(sys.FileSystem.exists(git_path)) {
                        log('> update $lib - git pull - run at ${cur.path}\n');
                        var pre = Sys.getCwd();
                        Sys.setCwd(cur.path);
                        Sys.command('git', ['pull', '--progress']);
                        Sys.command('git', ['submodule', 'update', '--init', '--recursive']);
                        Sys.setCwd(pre);
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
        log('> news [which]     |  list relevant dev log post (snowkit or luxe)');
        log('> update [lib]     |  update or install a lib (snow or luxe)');
        log('> status [lib]     |  check if there are updates on the repo for a lib (snow or luxe)');
        log('> test [lib]       |  run a web build of [lib] to validate correct setup (snow or luxe)');
        log('> shortcuts [path] |  install "flow" & "snowfall" command line shortcuts into [path]');
        log('\nnotes\n');
        log('> All dependencies of [lib] will be installed or updated.');
        log('> i.e `snowfall update luxe` will update snow, and flow.\n');

    } //help

} //M

package util;

import haxe.io.Path;
using StringTools;

@:publicFields
class U {

    static function normalize(path:String) : String
        return Path.removeTrailingSlashes(Path.normalize(normalize_slashes(path)));
    static function normalize_slashes(path:String) : String
        return path.replace('\\','/');

    static function run( cmd:String, ?args:Array<String>, ?path:String='', print=false ) {

        var last_path:String = '';
        if(args == null) args = [];

        if(path != null && path != '') {

            // log('util - run - changing directory to `$path` for `$cmd`');

            last_path = Sys.getCwd();
            Sys.setCwd(path);

        } //path

        args = args.map(function(arg) {
            if(arg.indexOf(' ') > -1) arg = '"$arg"';
            return arg;
        });

        // Sys.println('util - running : $cmd ${args.join(" ")}');

        var p = new sys.io.Process(cmd, args);
        var o = '';
        var e = '';

        if(!print) {
            e = p.stderr.readAll().toString();
            o = p.stdout.readAll().toString();
        } else {
            var done_out = false;
            var done_err = false;
            var done = false;
            var so = Sys.stdout();
            while(!done) {

                try {
                    so.writeString(p.stderr.readLine()+'\n');
                } catch(e:Dynamic) {
                    done_err = true;
                }

                try { 
                    so.writeString(p.stdout.readLine()+'\n'); 
                } catch(e:Dynamic) {
                    done_out = true;
                }

                done = done_out && done_err;
            }
        }

        var result = {
            err : e,
            out : o,
            code : p.exitCode()
        }

        if(last_path != '') {
            // log('util - run - reset directory to `$last_path`');
            Sys.setCwd(last_path);
        }

        return result;

    } //run

}
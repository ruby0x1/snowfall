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

    public static function rss(url:String) : Array<{ title:String, posted:String, date:Date, link:String }> {

        var data = haxe.Http.requestUrl(url);
        var xml = haxe.xml.Parser.parse(data, true);
        var rss = new haxe.xml.Fast(xml.firstElement());
        var channel = rss.node.channel;
        var res = [];
        var r_date = ~/(?:.*, ?)(\d+) ?(.{3}) ?(\d+)/;
        var date: Date = null;
        var posted = 'unknown';
        var months = ['jan' => '01', 'feb' => '02', 'mar' => '03', 'apr' => '04', 'may' => '05', 'jun' => '06', 'jul' => '07', 'aug' => '08', 'sep' => '09', 'oct' => '10', 'nov' => '11', 'dec' => '12'];

        for(item in channel.nodes.item) {
            
            if(r_date.match(item.node.pubDate.innerData)) {
                var dd = StringTools.lpad(r_date.matched(1),'0',2);
                var mon = r_date.matched(2);
                var mm = months.get(mon.toLowerCase());
                var yr = Std.parseInt(r_date.matched(3));
                date = Date.fromString('$yr-$mm-$dd');
                posted = '$dd $mon $yr';
            }

            res.push({
                date: date,
                posted: posted,
                link: item.node.link.innerData,
                title: item.node.title.innerData
            });
        }

        return res;

    } //rss

}
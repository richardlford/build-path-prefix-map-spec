#!/usr/bin/nodejs

var unquote = function(x) {
    return x.replace(/%\+/g, '=').replace(/%;/g, ':').replace(/%%/g, '%');
};

var parse_prefix_map = function(x) {
    return x ? x.split(/:+/g).map(function(part) {
        var tuples = part.split(/=/g).map(unquote);
        if (tuples.length !== 2) throw "invalid value: " + x;
        return tuples;
    }) : [];
}

var map_prefix = function(string, pm) {
    for (var i = pm.length - 1; i >= 0; --i) {;
        var src = pm[i][0];
        var dst = pm[i][1];
        if (string.indexOf(src) === 0) {
            return dst + string.substr(src.length);
        }
    }
    return string;
}

var pm = parse_prefix_map(process.env["BUILD_PATH_PREFIX_MAP"]);

// var i = 2 is just how nodejs yolos its way through common conventions
for (var i = 2, l = process.argv.length; i < l; ++i) {
    console.log(map_prefix(process.argv[i], pm));
}

/*
Original author: Daniele Linguaglossa
28/07/2021 -    Edited by Simone Quatrini
                Code amended to correctly run on the latest frida version
        		Added controls to exclude Magisk Manager
*/
// Interceptor.attach(Module.findExportByName("libc.so", "strstr"), {

//     onEnter: function(args) {

//         this.haystack = args[0];
//         this.needle = args[1];
//         this.frida = Boolean(0);

//         var haystack = Memory.readUtf8String(this.haystack);
//         var needle = Memory.readUtf8String(this.needle);

//         if (haystack.indexOf("frida") !== -1 || haystack.indexOf("xposed") !== -1) {
//             this.frida = Boolean(1);
//         }
//     },

//     onLeave: function(retval) {

//         if (this.frida) {
//             retval.replace(0);
//         }
//         return retval;
//     }
// });

/**
Root detection bypass script for Gantix JailMoney
https://github.com/GantMan/jail-monkey
**/
// Java.perform(() => {
//     const klass = Java.use("com.gantix.JailMonkey.JailMonkeyModule");
//     const hashmap_klass = Java.use("java.util.HashMap");
//     const false_obj = Java.use("java.lang.Boolean").FALSE.value;

//     klass.getConstants.implementation = function () {
//         var h = hashmap_klass.$new();
//         h.put("isJailBroken", false_obj);
//         h.put("hookDetected", false_obj);
//         h.put("canMockLocation", false_obj);
//         h.put("isOnExternalStorage", false_obj);
//         h.put("AdbEnabled", false_obj);
//         return h;
//     };
// });

/*
Java.perform(function()
{
    var string = Java.use("java.lang.String");
    string.intern.implementation = function ()
    {
        if (this.equals("frida"))
        {
            console.log("Bypass!");
            return "nope";
        }
        return this.intern();
    };
});


Java.perform(function()
{
    var hook = Java.use("java.lang.String");

    var overloadCount = hook['valueOf'].overloads.length;

    console.log("Tracing String.valueOf [" + overloadCount + " overload(s)]");

    for (var i = 0; i < overloadCount; i++) {

        hook['valueOf'].overloads[i].implementation = function ()
        {
            console.log(this);
            if (this.equals("frida"))
            {
                console.log("Bypass!");
                return "nope";
            }
            return this['valueOf'].apply(this, arguments);
//            return this.valueOf();
        };
    };
});
*/
// generic trace
function trace(pattern)
{
    var type = (pattern.toString().indexOf("!") === -1) ? "java" : "module";

    if (type === "module") {

        // trace Module
        var res = new ApiResolver("module");
        var matches = res.enumerateMatchesSync(pattern);
        var targets = uniqBy(matches, JSON.stringify);
        targets.forEach(function(target) {
            traceModule(target.address, target.name);
        });

    } else if (type === "java") {

        // trace Java Class
        var found = false;
        Java.enumerateLoadedClasses({
            onMatch: function(aClass) {
                if (aClass.match(pattern)) {
                    found = true;
                    var className = aClass;
                    try {
                        className = aClass.match(/[L](.*);/)[1].replace(/\//g, ".");                        
                    }
                    catch(err) {}
                    traceClass(className);
                }
            },
            onComplete: function() {}
        });

        // trace Java Method
        if (!found) {
            try {
                traceMethod(pattern);
            }
            catch(err) { // catch non existing classes/methods
                console.error(err);
            }
        }
    }
}

// find and trace all methods declared in a Java Class
function traceClass(targetClass)
{
    var hook = Java.use(targetClass);
    var methods = hook.class.getDeclaredMethods();
    hook.$dispose;

    var parsedMethods = [];
    methods.forEach(function(method) {
        parsedMethods.push(method.toString().replace(targetClass + ".", "TOKEN").match(/\sTOKEN(.*)\(/)[1]);
    });

    var targets = uniqBy(parsedMethods, JSON.stringify);
    targets.forEach(function(targetMethod) {
        traceMethod(targetClass + "." + targetMethod);
    });
}

// trace a specific Java Method
function traceMethod(targetClassMethod)
{
    var delim = targetClassMethod.lastIndexOf(".");
    if (delim === -1) return;

    var targetClass = targetClassMethod.slice(0, delim)
    var targetMethod = targetClassMethod.slice(delim + 1, targetClassMethod.length)

    var hook = Java.use(targetClass);
    var overloadCount = hook[targetMethod].overloads.length;

    console.log("Tracing " + targetClassMethod + " [" + overloadCount + " overload(s)]");

    for (var i = 0; i < overloadCount; i++) {

        hook[targetMethod].overloads[i].implementation = function() {

            if (targetClassMethod == "c.b0.c.B") {
                var retval = this[targetMethod].apply(this, arguments); // rare crash (Frida bug?)
                if (retval != null) { console.warn("-> decrypted string \"" + retval + "\""); }
                return retval;
            }

            if (targetClassMethod != null) { console.warn("\n*** entered " + targetClassMethod); }

            if (targetClassMethod == "l.b.i0.d.z") { console.warn("-> bypass"); return false; }

            //return false;

            // print backtrace
            // Java.perform(function() {
            //    var bt = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new());
            //    console.log("\nBacktrace:\n" + bt);
            // });   

            // print args
            if (arguments.length) console.log();
            for (var j = 0; j < arguments.length; j++) {
                console.log("arg[" + j + "]: " + String(arguments[j]) + " (" + typeof(arguments[j]) + ")");
                if (String(arguments[j]).includes('frida')) { 
                       console.log("arg[" + j + "]: " + String(arguments[j]) + " (" + typeof(arguments[j]) + ")");
                       Java.perform(function() {
                       var bt = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new());
                       console.log("\nBacktrace:\n" + bt);
                    }); 
                    return false;
                    };
                // if (String(arguments[j]).includes('saurik')) { return false; };
                // if (String(arguments[j]).includes('BC59E61A614B983A59A83E9E235614')) { return false; };
                // if (String(arguments[j]).includes('af87e95230ea394e5fa1fc6d1614cb1f')) { return false; };
                // if (String(arguments[j]).includes('510bca2f7f321471c0c287b1ec148b15')) { return false; };
                // if (String(arguments[j]).includes('c45de837540c7ca447946197d3870eb7')) { return false; };

                //af87e95230ea394e5fa1fc6d1614cb1f
                //510bca2f7f321471c0c287b1ec148b15
                //c45de837540c7ca447946197d3870eb7
            }

            // print retval
            var retval = this[targetMethod].apply(this, arguments); // rare crash (Frida bug?)

            // if (retval) {
            //     for (var j = 0; j < arguments.length; j++) {
            //         console.log("arg[" + j + "]: " + String(arguments[j]) + " (" + typeof(arguments[j]) + ")");
            //     }
            //     console.log(retval);
            // }
            //console.warn("\n*** exiting " + targetClassMethod);
            return retval;
        }
    }
}

// trace Module functions
function traceModule(impl, name)
{
    console.log("Tracing module " + name);

    Interceptor.attach(impl, {

        onEnter: function(args) {
            console.warn("\n*** module entered " + name);

            // debug only the intended calls
            this.flag = false;
            // var filename = Memory.readCString(ptr(args[0]));
            // if (filename.indexOf("XYZ") === -1 && filename.indexOf("ZYX") === -1) // exclusion list
            // if (filename.indexOf("my.interesting.file") !== -1) // inclusion list
                this.flag = true;

            if (this.flag) {
                console.warn("\n*** module entered " + name);

                // print backtrace
                //console.log("\nBacktrace:\n" + Thread.backtrace(this.context, Backtracer.ACCURATE)
                //        .map(DebugSymbol.fromAddress).join("\n"));
            }
        },

        onLeave: function(retval) {

            if (this.flag) {
                // print retval
                console.warn("\n*** module exiting " + name);
                console.log(retval);
            }
        }

    });
}

// remove duplicates from array
function uniqBy(array, key)
{
        var seen = {};
        return array.filter(function(item) {
                var k = key(item);
                return seen.hasOwnProperty(k) ? false : (seen[k] = true);
        });
}

// usage examples
setTimeout(function() { // avoid java.lang.ClassNotFoundException

    Java.perform(function() {
//        trace("net.veritran.smart.e.getChars");
//        trace("java.lang.String.valueOf");
//        trace("java.lang.String.hashCode");

//        trace("java.lang.String.equals");
//        trace("l.b.i0.d.z");
//        trace("c.b0.c.i0");
//        trace("c.b0.c.B");
/*
        const strenc = Java.use("c.b0.c");
        strenc.B.implementation = function() {
            var retval = this.B(arguments[0],arguments[1],arguments[2]);
            if (retval != null) { console.warn("-> decrypted string \"" + retval + "\""); }
            return retval;
      }
*/
//        trace("java.lang.StringBuilder.append")
        //trace("com.android.okhttp.OkHttpClient$1.put");
        // trace("com.target.utils.CryptoUtils.decrypt");
        // trace("com.target.utils.CryptoUtils");
        // trace("CryptoUtils");
        // trace(/crypto/i);
        // trace("exports:*!open*");

    });   
}, 0);

Java.perform(function() {
    var RootPackages = ["com.noshufou.android.su", "com.noshufou.android.su.elite", "eu.chainfire.supersu",
        "com.koushikdutta.superuser", "com.thirdparty.superuser", "com.yellowes.su", "com.koushikdutta.rommanager",
        "com.koushikdutta.rommanager.license", "com.dimonvideo.luckypatcher", "com.chelpus.lackypatch",
        "com.ramdroid.appquarantine", "com.ramdroid.appquarantinepro", "com.devadvance.rootcloak", "com.devadvance.rootcloakplus",
        "de.robv.android.xposed.installer", "com.saurik.substrate", "com.zachspong.temprootremovejb", "com.amphoras.hidemyroot",
        "com.amphoras.hidemyrootadfree", "com.formyhm.hiderootPremium", "com.formyhm.hideroot", "me.phh.superuser",
        "eu.chainfire.supersu.pro", "com.kingouser.com", "com.topjohnwu.magisk"
    ];

    var RootBinaries = ["su", "busybox", "supersu", "Superuser.apk", "KingoUser.apk", "SuperSu.apk", "magisk"];

    var RootProperties = {
        "ro.build.selinux": "1",
        "ro.debuggable": "0",
        "service.adb.root": "0",
        "ro.secure": "1"
    };

    var RootPropertiesKeys = [];

    for (var k in RootProperties) RootPropertiesKeys.push(k);

    var PackageManager = Java.use("android.app.ApplicationPackageManager");

    var Runtime = Java.use('java.lang.Runtime');

    var NativeFile = Java.use('java.io.File');

    var String = Java.use('java.lang.String');

    var SystemProperties = Java.use('android.os.SystemProperties');

    var BufferedReader = Java.use('java.io.BufferedReader');

    var ProcessBuilder = Java.use('java.lang.ProcessBuilder');

    var StringBuffer = Java.use('java.lang.StringBuffer');

    var loaded_classes = Java.enumerateLoadedClassesSync();

    send("Loaded " + loaded_classes.length + " classes!");

    var useKeyInfo = false;

    var useProcessManager = false;

    send("loaded: " + loaded_classes.indexOf('java.lang.ProcessManager'));

    if (loaded_classes.indexOf('java.lang.ProcessManager') != -1) {
        try {
            //useProcessManager = true;
            //var ProcessManager = Java.use('java.lang.ProcessManager');
        } catch (err) {
            send("ProcessManager Hook failed: " + err);
        }
    } else {
        send("ProcessManager hook not loaded");
    }

    var KeyInfo = null;

    if (loaded_classes.indexOf('android.security.keystore.KeyInfo') != -1) {
        try {
            //useKeyInfo = true;
            //var KeyInfo = Java.use('android.security.keystore.KeyInfo');
        } catch (err) {
            send("KeyInfo Hook failed: " + err);
        }
    } else {
        send("KeyInfo hook not loaded");
    }

    PackageManager.getPackageInfo.overload('java.lang.String', 'int').implementation = function(pname, flags) {
        var shouldFakePackage = (RootPackages.indexOf(pname) > -1);
        if (shouldFakePackage) {
            send("Bypass root check for package: " + pname);
            pname = "set.package.name.to.a.fake.one.so.we.can.bypass.it";
        }
        return this.getPackageInfo.overload('java.lang.String', 'int').call(this, pname, flags);
    };

    NativeFile.exists.implementation = function() {
        var name = NativeFile.getName.call(this);
        var shouldFakeReturn = (RootBinaries.indexOf(name) > -1);
        if (shouldFakeReturn) {
            send("Bypass return value for binary: " + name);
            return false;
        } else {
            return this.exists.call(this);
        }
    };

    var exec = Runtime.exec.overload('[Ljava.lang.String;');
    var exec1 = Runtime.exec.overload('java.lang.String');
    var exec2 = Runtime.exec.overload('java.lang.String', '[Ljava.lang.String;');
    var exec3 = Runtime.exec.overload('[Ljava.lang.String;', '[Ljava.lang.String;');
    var exec4 = Runtime.exec.overload('[Ljava.lang.String;', '[Ljava.lang.String;', 'java.io.File');
    var exec5 = Runtime.exec.overload('java.lang.String', '[Ljava.lang.String;', 'java.io.File');

    exec5.implementation = function(cmd, env, dir) {
        if (cmd.indexOf("getprop") != -1 || cmd == "mount" || cmd.indexOf("build.prop") != -1 || cmd == "id" || cmd == "sh") {
            var fakeCmd = "grep";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        if (cmd == "su") {
            var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        return exec5.call(this, cmd, env, dir);
    };

    exec4.implementation = function(cmdarr, env, file) {
        for (var i = 0; i < cmdarr.length; i = i + 1) {
            var tmp_cmd = cmdarr[i];
            if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd == "mount" || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd == "id" || tmp_cmd == "sh") {
                var fakeCmd = "grep";
                send("Bypass " + cmdarr + " command");
                return exec1.call(this, fakeCmd);
            }

            if (tmp_cmd == "su") {
                var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
                send("Bypass " + cmdarr + " command");
                return exec1.call(this, fakeCmd);
            }
        }
        return exec4.call(this, cmdarr, env, file);
    };

    exec3.implementation = function(cmdarr, envp) {
        for (var i = 0; i < cmdarr.length; i = i + 1) {
            var tmp_cmd = cmdarr[i];
            if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd == "mount" || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd == "id" || tmp_cmd == "sh") {
                var fakeCmd = "grep";
                send("Bypass " + cmdarr + " command");
                return exec1.call(this, fakeCmd);
            }

            if (tmp_cmd == "su") {
                var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
                send("Bypass " + cmdarr + " command");
                return exec1.call(this, fakeCmd);
            }
        }
        return exec3.call(this, cmdarr, envp);
    };

    exec2.implementation = function(cmd, env) {
        if (cmd.indexOf("getprop") != -1 || cmd == "mount" || cmd.indexOf("build.prop") != -1 || cmd == "id" || cmd == "sh") {
            var fakeCmd = "grep";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        if (cmd == "su") {
            var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        return exec2.call(this, cmd, env);
    };

    exec.implementation = function(cmd) {
        for (var i = 0; i < cmd.length; i = i + 1) {
            var tmp_cmd = cmd[i];
            if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd == "mount" || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd == "id" || tmp_cmd == "sh") {
                var fakeCmd = "grep";
                send("Bypass " + cmd + " command");
                return exec1.call(this, fakeCmd);
            }

            if (tmp_cmd == "su") {
                var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
                send("Bypass " + cmd + " command");
                return exec1.call(this, fakeCmd);
            }
        }

        return exec.call(this, cmd);
    };

    exec1.implementation = function(cmd) {
        if (cmd.indexOf("getprop") != -1 || cmd == "mount" || cmd.indexOf("build.prop") != -1 || cmd == "id" || cmd == "sh") {
            var fakeCmd = "grep";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        if (cmd == "su") {
            var fakeCmd = "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled";
            send("Bypass " + cmd + " command");
            return exec1.call(this, fakeCmd);
        }
        return exec1.call(this, cmd);
    };

    String.contains.implementation = function(name) {
        if (name == "test-keys") {
            send("Bypass test-keys check");
            return false;
        }
        return this.contains.call(this, name);
    };

    var get = SystemProperties.get.overload('java.lang.String');

    get.implementation = function(name) {
        if (RootPropertiesKeys.indexOf(name) != -1) {
            send("Bypass " + name);
            return RootProperties[name];
        }
        return this.get.call(this, name);
    };

    Interceptor.attach(Module.findExportByName("libc.so", "fopen"), {
        onEnter: function(args) {
            var path = Memory.readCString(args[0]);
            path = path.split("/");
            var executable = path[path.length - 1];
            var shouldFakeReturn = (RootBinaries.indexOf(executable) > -1)
            if (shouldFakeReturn) {
                Memory.writeUtf8String(args[0], "/notexists");
                send("Bypass native fopen");
            }
        },
        onLeave: function(retval) {

        }
    });

    Interceptor.attach(Module.findExportByName("libc.so", "system"), {
        onEnter: function(args) {
            var cmd = Memory.readCString(args[0]);
            send("SYSTEM CMD: " + cmd);
            if (cmd.indexOf("getprop") != -1 || cmd == "mount" || cmd.indexOf("build.prop") != -1 || cmd == "id") {
                send("Bypass native system: " + cmd);
                Memory.writeUtf8String(args[0], "grep");
            }
            if (cmd == "su") {
                send("Bypass native system: " + cmd);
                Memory.writeUtf8String(args[0], "justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled");
            }
        },
        onLeave: function(retval) {

        }
    });

    /*

    TO IMPLEMENT:

    Exec Family

    int execl(const char *path, const char *arg0, ..., const char *argn, (char *)0);
    int execle(const char *path, const char *arg0, ..., const char *argn, (char *)0, char *const envp[]);
    int execlp(const char *file, const char *arg0, ..., const char *argn, (char *)0);
    int execlpe(const char *file, const char *arg0, ..., const char *argn, (char *)0, char *const envp[]);
    int execv(const char *path, char *const argv[]);
    int execve(const char *path, char *const argv[], char *const envp[]);
    int execvp(const char *file, char *const argv[]);
    int execvpe(const char *file, char *const argv[], char *const envp[]);

    */


    BufferedReader.readLine.overload('boolean').implementation = function() {
        var text = this.readLine.overload('boolean').call(this);
        if (text === null) {
            // just pass , i know it's ugly as hell but test != null won't work :(
        } else {
            var shouldFakeRead = (text.indexOf("ro.build.tags=test-keys") > -1);
            if (shouldFakeRead) {
                send("Bypass build.prop file read");
                text = text.replace("ro.build.tags=test-keys", "ro.build.tags=release-keys");
            }
        }
        return text;
    };

    var executeCommand = ProcessBuilder.command.overload('java.util.List');

    ProcessBuilder.start.implementation = function() {
        var cmd = this.command.call(this);
        var shouldModifyCommand = false;
        for (var i = 0; i < cmd.size(); i = i + 1) {
            var tmp_cmd = cmd.get(i).toString();
            if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd.indexOf("mount") != -1 || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd.indexOf("id") != -1) {
                shouldModifyCommand = true;
            }
        }
        if (shouldModifyCommand) {
            send("Bypass ProcessBuilder " + cmd);
            this.command.call(this, ["grep"]);
            return this.start.call(this);
        }
        if (cmd.indexOf("su") != -1) {
            send("Bypass ProcessBuilder " + cmd);
            this.command.call(this, ["justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled"]);
            return this.start.call(this);
        }

        return this.start.call(this);
    };

    if (useProcessManager) {
        var ProcManExec = ProcessManager.exec.overload('[Ljava.lang.String;', '[Ljava.lang.String;', 'java.io.File', 'boolean');
        var ProcManExecVariant = ProcessManager.exec.overload('[Ljava.lang.String;', '[Ljava.lang.String;', 'java.lang.String', 'java.io.FileDescriptor', 'java.io.FileDescriptor', 'java.io.FileDescriptor', 'boolean');

        ProcManExec.implementation = function(cmd, env, workdir, redirectstderr) {
            var fake_cmd = cmd;
            for (var i = 0; i < cmd.length; i = i + 1) {
                var tmp_cmd = cmd[i];
                if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd == "mount" || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd == "id") {
                    var fake_cmd = ["grep"];
                    send("Bypass " + cmdarr + " command");
                }

                if (tmp_cmd == "su") {
                    var fake_cmd = ["justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled"];
                    send("Bypass " + cmdarr + " command");
                }
            }
            return ProcManExec.call(this, fake_cmd, env, workdir, redirectstderr);
        };

        ProcManExecVariant.implementation = function(cmd, env, directory, stdin, stdout, stderr, redirect) {
            var fake_cmd = cmd;
            for (var i = 0; i < cmd.length; i = i + 1) {
                var tmp_cmd = cmd[i];
                if (tmp_cmd.indexOf("getprop") != -1 || tmp_cmd == "mount" || tmp_cmd.indexOf("build.prop") != -1 || tmp_cmd == "id") {
                    var fake_cmd = ["grep"];
                    send("Bypass " + cmdarr + " command");
                }

                if (tmp_cmd == "su") {
                    var fake_cmd = ["justafakecommandthatcannotexistsusingthisshouldthowanexceptionwheneversuiscalled"];
                    send("Bypass " + cmdarr + " command");
                }
            }
            return ProcManExecVariant.call(this, fake_cmd, env, directory, stdin, stdout, stderr, redirect);
        };
    }

    if (useKeyInfo) {
        KeyInfo.isInsideSecureHardware.implementation = function() {
            send("Bypass isInsideSecureHardware");
            return true;
        }
    }

});


setTimeout(function() {
    Java.perform(function() {
        var androidSettings = ['adb_enabled'];
        var sdkVersion = Java.use('android.os.Build$VERSION');
        console.log("SDK Version : " + sdkVersion.SDK_INT.value);

        /* API 16 or lower Settings.Global Hook */
        // if (sdkVersion.SDK_INT.value <= 16) {
            var settingSecure = Java.use('android.provider.Settings$Secure');

            settingSecure.getInt.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingSecure.getInt(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Secure.getInt(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getInt(cr, name);
                return ret;
            }

            settingSecure.getInt.overload('android.content.ContentResolver', 'java.lang.String', 'int').implementation = function(cr, name, def) {
                //console.log("[*]settingSecure.getInt(cr,name,def) : " + name);
                if (name == (androidSettings[0])) {
                    console.log('[+]Secure.getInt(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getInt(cr, name, def);
                return ret;
            }

            settingSecure.getFloat.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingSecure.getFloat(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Secure.getFloat(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getFloat(cr, name)
                return ret;
            }

            settingSecure.getFloat.overload('android.content.ContentResolver', 'java.lang.String', 'float').implementation = function(cr, name, def) {
                //console.log("[*]settingSecure.getFloat(cr,name,def) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Secure.getFloat(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getFloat(cr, name, def);
                return ret;
            }

            settingSecure.getLong.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingSecure.getLong(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Secure.getLong(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getLong(cr, name)
                return ret;
            }

            settingSecure.getLong.overload('android.content.ContentResolver', 'java.lang.String', 'long').implementation = function(cr, name, def) {
                //console.log("[*]settingSecure.getLong(cr,name,def) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Secure.getLong(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getLong(cr, name, def);
                return ret;
            }

            settingSecure.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingSecure.getString(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    var stringClass = Java.use("java.lang.String");
                    var stringInstance = stringClass.$new("0");

                    console.log('[+]Secure.getString(cr, name) Bypassed');
                    return stringInstance;
                }
                var ret = this.getString(cr, name);
                return ret;
            }
        // }

        // /* API 17 or higher Settings.Global Hook */
        // if (sdkVersion.SDK_INT.value >= 17) {
            var settingGlobal = Java.use('android.provider.Settings$Global');

            settingGlobal.getInt.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingGlobal.getInt(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Global.getInt(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getInt(cr, name);
                return ret;
            }

            settingGlobal.getInt.overload('android.content.ContentResolver', 'java.lang.String', 'int').implementation = function(cr, name, def) {
                //console.log("[*]settingGlobal.getInt(cr,name,def) : " + name);
                if (name == (androidSettings[0])) {
                    console.log('[+]Global.getInt(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getInt(cr, name, def);
                return ret;
            }

            settingGlobal.getFloat.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingGlobal.getFloat(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Global.getFloat(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getFloat(cr, name);
                return ret;
            }

            settingGlobal.getFloat.overload('android.content.ContentResolver', 'java.lang.String', 'float').implementation = function(cr, name, def) {
                //console.log("[*]settingGlobal.getFloat(cr,name,def) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Global.getFloat(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getFloat(cr, name, def);
                return ret;
            }

            settingGlobal.getLong.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingGlobal.getLong(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Global.getLong(cr, name) Bypassed');
                    return 0;
                }
                var ret = this.getLong(cr, name);
                return ret;
            }

            settingGlobal.getLong.overload('android.content.ContentResolver', 'java.lang.String', 'long').implementation = function(cr, name, def) {
                //console.log("[*]settingGlobal.getLong(cr,name,def) : " + name);
                if (name == androidSettings[0]) {
                    console.log('[+]Global.getLong(cr, name, def) Bypassed');
                    return 0;
                }
                var ret = this.getLong(cr, name, def);
                return ret;
            }

            settingGlobal.getString.overload('android.content.ContentResolver', 'java.lang.String').implementation = function(cr, name) {
                //console.log("[*]settingGlobal.getString(cr,name) : " + name);
                if (name == androidSettings[0]) {
                    var stringClass = Java.use("java.lang.String");
                    var stringInstance = stringClass.$new("0");

                    console.log('[+]Global.getString(cr, name) Bypassed');
                    return stringInstance;
                }
                var ret = this.getString(cr, name);
                return ret;
            }
        // }
    });
}, 0);

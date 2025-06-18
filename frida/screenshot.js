Java.perform(function () {

    // bypass ADT signature checking //////////////////////////////////////////

    // Obtain the class where the target method is located
    // var SigningUtils = Java.use('com.alarm.alarmmobile.android.util.SigningUtils');

    // Hook the isSignatureValid method
    // SigningUtils.isSignatureValid.overload('android.content.Context').implementation = function (context) {
    //    console.log('isSignatureValid hooked');
    //    return true;
    // };

    // bypass FLAG_SECURE /////////////////////////////////////////////////////

    var surface_view = Java.use('android.view.SurfaceView');
    var set_secure = surface_view.setSecure.overload('boolean');

    set_secure.implementation = function(flag){
        console.log("setSecure() flag called with args: " + flag); 
        set_secure.call(false);
    };

    var window = Java.use('android.view.Window');
    var set_flags = window.setFlags.overload('int', 'int');

    var window_manager = Java.use('android.view.WindowManager');
    var layout_params = Java.use('android.view.WindowManager$LayoutParams');

    set_flags.implementation = function(flags, mask){

        // print backtrace
        Java.perform(function() {
            var bt = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new());
            console.log("\nBacktrace:\n" + bt);
        });   

        //console.log(Object.getOwnPropertyNames(window.__proto__).join('\n'));
        console.log("flag secure: " + layout_params.FLAG_SECURE.value);

        console.log("before setflags called  flags:  "+ flags);
        flags =(flags.value & ~layout_params.FLAG_SECURE.value);
        console.log("after setflags called  flags:  "+ flags);

        set_flags.call(this, flags, mask);
    };
});
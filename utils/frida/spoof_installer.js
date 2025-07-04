Java.perform(function () {
    var context = Java.use("android.app.ActivityThread").currentApplication().getApplicationContext();
    var pm = context.getPackageManager();
    
    // Hook a getInstallerPackageName(String packageName)
    var PackageManager = Java.use("android.app.ApplicationPackageManager");
    PackageManager.getInstallerPackageName.overload('java.lang.String').implementation = function (pkg) {
        console.log("[+] getInstallerPackageName interceptado para: " + pkg);
        return "com.android.vending";  // Finge que fue instalada desde Play Store
    };
});
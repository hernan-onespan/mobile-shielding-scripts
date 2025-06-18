// Attach to the target app
const targetAppName = "com.netflix.starfire";

// Find the classes related to reflection
const classLoader = Java.classFactory.loader;
const classClass = Java.use("java.lang.Class");
const reflectionClasses = ["java.lang.reflect.Constructor", "java.lang.reflect.Method", "java.lang.reflect.Field"];

// Intercept the methods used for reflection
reflectionClasses.forEach(reflectionClass => {
  const clazz = Java.use(reflectionClass);
  clazz.$init.overload().implementation = function() {
    console.log(`Reflection class ${reflectionClass} constructor called`);
    const stackTrace = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Throwable").$new());
    console.log(stackTrace);
    this.$init.apply(this, arguments);
  };
});

Java.enumerateClassLoaders({
        onMatch: function(loader){
            Java.classFactory.loader = loader;

            // Intercept the class loading
            loader.loadClass.overload('java.lang.String').implementation = function(className) {
              const loadedClass = this.loadClass(className);
              const classSimpleName = classClass.getSimpleName.call(loadedClass);
              console.log(`preserve ${loadedClass};`);
              // const stackTrace = Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Throwable").$new());
              // console.log(stackTrace);
              return loadedClass;
            };
        },
        onComplete: function(){

        }
    });
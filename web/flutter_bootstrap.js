{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine({
        useColorEmoji: true,
      });
      await appRunner.runApp();
      if (typeof removeSplashFromWeb === "function") {
        removeSplashFromWeb();
      }
    } catch (e) {
      console.error("Flutter engine runner failed:", e);
      if (typeof removeSplashFromWeb === "function") {
        removeSplashFromWeb();
      }
    }
  }
});

const path = require('path');
const pkg = require('../package.json');

/**
 * Point autolinking at the library in the parent directory.
 *
 * The workspace dependency (`"link:.."`) resolves as a Yarn *soft* link, so
 * `example/node_modules/<pkg>` is never created. Autolinking discovers native
 * dependencies by scanning `node_modules`, so without this it finds nothing:
 * the podspec is skipped on iOS and no Gradle module is added on Android, and
 * the example builds as a JS-only app that cannot exercise the native code.
 *
 * Metro resolves the library separately, via `extraNodeModules` in metro.config.js.
 */
module.exports = {
  dependencies: {
    [pkg.name]: {
      root: path.join(__dirname, '..'),
    },
  },
};
